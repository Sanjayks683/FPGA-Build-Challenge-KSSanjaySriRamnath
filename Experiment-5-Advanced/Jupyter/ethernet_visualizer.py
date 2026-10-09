import io
import time
import math
import numpy as np

try:
    import cv2
    HAS_OPENCV = True
except ImportError:
    HAS_OPENCV = False

try:
    from PIL import Image as PILImage
    HAS_PIL = True
except ImportError:
    HAS_PIL = False

try:
    from IPython.display import display, Image as IPImage, clear_output
    HAS_IPYTHON = True
except ImportError:
    HAS_IPYTHON = False

def encode_frame_to_jpeg(frame_rgb, quality=80):
    if HAS_OPENCV:
        frame_bgr = cv2.cvtColor(frame_rgb, cv2.COLOR_RGB2BGR)
        success, buf = cv2.imencode('.jpg', frame_bgr, [int(cv2.IMWRITE_JPEG_QUALITY), quality])
        if success:
            return buf.tobytes()
    if HAS_PIL:
        pil_img = PILImage.fromarray(frame_rgb)
        buf = io.BytesIO()
        pil_img.save(buf, format='JPEG', quality=quality)
        return buf.getvalue()
    raise RuntimeError("Neither OpenCV nor Pillow is available.")

class RLHardwareDriver:
    REG_CTRL           = 0x0000
    REG_STATUS         = 0x0004
    REG_ALPHA          = 0x0008
    REG_GAMMA          = 0x000C
    REG_INIT_EPSILON   = 0x0010
    REG_MAX_EPISODES   = 0x0014
    REG_SLOW_DIVIDER   = 0x0018
    REG_CURRENT_EP     = 0x001C
    REG_CURRENT_STEPS  = 0x0020
    REG_REWARD_TOTAL   = 0x0024
    REG_AGENT_POS      = 0x0028
    REG_BEST_STEPS     = 0x002C
    REG_CURRENT_EPS    = 0x0030
    REG_TOTAL_GOALS    = 0x0034
    BASE_Q_TABLE       = 0x0100
    BASE_HISTORY       = 0x0300
    REG_MAZE_LOW       = 0x1000
    REG_MAZE_HIGH      = 0x1004

    def __init__(self, mmio_handle):
        self.mmio = mmio_handle

    def reset(self):
        self.mmio.write(self.REG_CTRL, 0x02)
        time.sleep(0.005)

    def configure(self, alpha=0.10, gamma=0.95, epsilon=0.90, max_episodes=2000, slow_divider=2500000):


        alpha_fixed = int(round(alpha * 256.0)) & 0xFF
        gamma_fixed = int(round(gamma * 256.0)) & 0xFF
        eps_fixed   = int(round(epsilon * 256.0)) & 0xFF
        self.mmio.write(self.REG_ALPHA, alpha_fixed)
        self.mmio.write(self.REG_GAMMA, gamma_fixed)
        self.mmio.write(self.REG_INIT_EPSILON, eps_fixed)
        self.mmio.write(self.REG_MAX_EPISODES, max_episodes)
        self.mmio.write(self.REG_SLOW_DIVIDER, slow_divider)

    def start_training(self, slow_mode=False):
        ctrl = 0x01
        if slow_mode:
            ctrl |= 0x04
        self.mmio.write(self.REG_CTRL, ctrl)


    def get_status(self):
        status_raw  = self.mmio.read(self.REG_STATUS)
        pos_raw     = self.mmio.read(self.REG_AGENT_POS)
        reward_raw  = self.mmio.read(self.REG_REWARD_TOTAL)
        eps_raw     = self.mmio.read(self.REG_CURRENT_EPS)
        best_raw    = self.mmio.read(self.REG_BEST_STEPS)
        if reward_raw & 0x80000000:
            reward_raw -= 0x100000000
        reward_float = reward_raw / 256.0
        agent_row = (pos_raw >> 4) & 0x07
        agent_col = pos_raw & 0x07
        epsilon_float = (eps_raw & 0xFFFF) / 65536.0
        training = bool(status_raw & 0x01)
        return {
            "training":     training,
            "busy":         training,
            "done":         bool(status_raw & 0x02),
            "episode":      self.mmio.read(self.REG_CURRENT_EP),
            "steps":        self.mmio.read(self.REG_CURRENT_STEPS),
            "reward":       reward_float,
            "agent_row":    agent_row,
            "agent_col":    agent_col,
            "best_steps":   best_raw,
            "epsilon":      epsilon_float,
            "total_goals":  self.mmio.read(self.REG_TOTAL_GOALS)
        }

    def read_q_table(self):
        q_table = np.zeros((64, 4), dtype=np.float32)
        for state in range(64):
            w0 = self.mmio.read(self.BASE_Q_TABLE + state * 8)
            w1 = self.mmio.read(self.BASE_Q_TABLE + state * 8 + 4)
            q0_raw = w0 & 0xFFFF
            q1_raw = (w0 >> 16) & 0xFFFF
            q2_raw = w1 & 0xFFFF
            q3_raw = (w1 >> 16) & 0xFFFF
            for act, val_raw in enumerate([q0_raw, q1_raw, q2_raw, q3_raw]):
                if val_raw & 0x8000:
                    val_raw -= 0x10000
                q_table[state, act] = val_raw / 256.0
        return q_table

    def read_history(self, count=100):
        total = self.mmio.read(self.REG_CURRENT_EP)
        count = min(100, count, total)
        history = []
        for episode in range(total - count + 1, total + 1):
            val = self.mmio.read(self.BASE_HISTORY + ((episode - 1) % 100) * 4)
            history.append({
                "episode":      episode,
                "goal_reached": bool(val >> 31),
                "steps":        val & 0x00FFFFFF,
            })
        return history

    def write_maze(self, maze_bits_64):
        low_32  = maze_bits_64 & 0xFFFFFFFF
        high_32 = (maze_bits_64 >> 32) & 0xFFFFFFFF
        self.mmio.write(self.REG_MAZE_LOW, low_32)
        self.mmio.write(self.REG_MAZE_HIGH, high_32)

    def read_maze(self):
        low_32  = self.mmio.read(self.REG_MAZE_LOW)
        high_32 = self.mmio.read(self.REG_MAZE_HIGH)
        return (high_32 << 32) | (low_32 & 0xFFFFFFFF)

class GridRenderer:
    def __init__(self, width=640, height=480):
        self.width = width
        self.height = height
        self.grid_size = 8
        self.cell_px = 44
        self.offset_x = 48
        self.offset_y = 64
        self.COLOR_BG       = (18, 22, 28)
        self.COLOR_PANEL    = (28, 36, 46)
        self.COLOR_BORDER   = (50, 65, 82)
        self.COLOR_START    = (30, 144, 255)
        self.COLOR_GOAL     = (255, 215, 0)
        self.COLOR_WALL     = (45, 52, 60)
        self.COLOR_AGENT    = (255, 255, 255)
        self.COLOR_AGENT_RING = (0, 245, 255)
        self.COLOR_ARROW    = (220, 240, 255)

    def _get_heat_color(self, val, min_v=-10.0, max_v=100.0):
        norm = (val - min_v) / (max_v - min_v + 1e-6)
        norm = max(0.0, min(1.0, norm))
        if norm < 0.25:
            t = norm / 0.25
            r = int(180 + 75 * t)
            g = int(30 * t)
            b = int(30 * (1 - t))
        elif norm < 0.60:
            t = (norm - 0.25) / 0.35
            r = int(255)
            g = int(100 + 155 * t)
            b = 20
        else:
            t = (norm - 0.60) / 0.40
            r = int(255 * (1 - t))
            g = int(230 + 25 * t)
            b = int(40 + 60 * t)
        return (max(0, min(255, r)), max(0, min(255, g)), max(0, min(255, b)))

    def render(self, q_table, agent_row, agent_col, maze_mask, stats):
        frame = np.full((self.height, self.width, 3), self.COLOR_BG, dtype=np.uint8)
        if HAS_OPENCV:
            cv2.rectangle(frame, (16, 16), (self.width - 16, self.height - 16), (32, 42, 54), 1)
            cv2.rectangle(frame, (430, 52), (618, 436), self.COLOR_PANEL, -1)
            cv2.rectangle(frame, (430, 52), (618, 436), self.COLOR_BORDER, 1)

        max_q_grid = np.max(q_table, axis=1).reshape((8, 8))
        best_act_grid = np.argmax(q_table, axis=1).reshape((8, 8))

        for r in range(self.grid_size):
            for c in range(self.grid_size):
                x0 = self.offset_x + c * self.cell_px
                y0 = self.offset_y + r * self.cell_px
                x1 = x0 + self.cell_px
                y1 = y0 + self.cell_px
                cell_idx = r * 8 + c
                is_start = (r == 0 and c == 0)
                is_goal  = (r == 7 and c == 7)
                is_wall  = bool((maze_mask >> cell_idx) & 1) and not is_start and not is_goal
                if is_start:
                    cell_color = self.COLOR_START
                elif is_goal:
                    cell_color = self.COLOR_GOAL
                elif is_wall:
                    cell_color = self.COLOR_WALL
                else:
                    q_val = max_q_grid[r, c]
                    cell_color = self._get_heat_color(q_val, min_v=-2.0, max_v=100.0)

                frame[y0:y1, x0:x1] = cell_color
                if HAS_OPENCV:
                    cv2.rectangle(frame, (x0, y0), (x1, y1), self.COLOR_BORDER, 1)
                    if not is_wall and not is_goal:
                        best_act = best_act_grid[r, c]
                        cx = (x0 + x1) // 2
                        cy = (y0 + y1) // 2
                        arrow_len = 10
                        dx, dy = 0, 0
                        if best_act == 0:   dy = -arrow_len
                        elif best_act == 1: dy = arrow_len
                        elif best_act == 2: dx = -arrow_len
                        elif best_act == 3: dx = arrow_len
                        if abs(max_q_grid[r, c]) > 0.1:
                            cv2.arrowedLine(frame, (cx - dx//2, cy - dy//2),
                                            (cx + dx, cy + dy),
                                            self.COLOR_ARROW, 1, tipLength=0.35)
                    if is_start:
                        cv2.putText(frame, "START", (x0 + 4, y0 + 30), cv2.FONT_HERSHEY_SIMPLEX, 0.35, (255, 255, 255), 1)
                    elif is_goal:
                        cv2.putText(frame, "GOAL", (x0 + 6, y0 + 30), cv2.FONT_HERSHEY_SIMPLEX, 0.4, (20, 20, 20), 1)
                    elif is_wall:
                        cv2.line(frame, (x0+4, y0+4), (x1-4, y1-4), (70, 80, 92), 1)
                        cv2.line(frame, (x0+4, y1-4), (x1-4, y0+4), (70, 80, 92), 1)

        agent_cx = self.offset_x + agent_col * self.cell_px + self.cell_px // 2
        agent_cy = self.offset_y + agent_row * self.cell_px + self.cell_px // 2

        if HAS_OPENCV:
            cv2.circle(frame, (agent_cx, agent_cy), 14, self.COLOR_AGENT_RING, 2)
            cv2.circle(frame, (agent_cx, agent_cy), 8, self.COLOR_AGENT, -1)
            cv2.putText(frame, "V-SPACE 2026: HARDWARE Q-LEARNING (ETHERNET STREAM)",
                        (28, 36), cv2.FONT_HERSHEY_SIMPLEX, 0.50, (240, 245, 255), 1)
            sx = 444
            cv2.putText(frame, "LIVE TELEMETRY", (sx, 80), cv2.FONT_HERSHEY_SIMPLEX, 0.45, (0, 245, 255), 1)
            cv2.line(frame, (sx, 88), (604, 88), (50, 65, 82), 1)
            ep = stats.get("episode", 0)
            st = stats.get("steps", 0)
            eps = stats.get("epsilon", 0.9)
            best_p = stats.get("best_steps", 0)
            goals = stats.get("total_goals", 0)
            is_train = stats.get("training", True)
            cv2.putText(frame, f"Episode:  {ep:04d}", (sx, 120), cv2.FONT_HERSHEY_SIMPLEX, 0.42, (220, 230, 240), 1)
            cv2.putText(frame, f"Steps:    {st:03d}", (sx, 150), cv2.FONT_HERSHEY_SIMPLEX, 0.42, (220, 230, 240), 1)
            cv2.putText(frame, f"Epsilon:  {eps:.3f}", (sx, 180), cv2.FONT_HERSHEY_SIMPLEX, 0.42, (255, 180, 60), 1)
            cv2.putText(frame, f"Goals:    {goals}", (sx, 210), cv2.FONT_HERSHEY_SIMPLEX, 0.42, (100, 255, 120), 1)
            best_str = f"{best_p} steps" if best_p < 9999 else "Exploring..."
            cv2.putText(frame, f"Best Path:", (sx, 240), cv2.FONT_HERSHEY_SIMPLEX, 0.42, (220, 230, 240), 1)
            cv2.putText(frame, f"  {best_str}", (sx, 262), cv2.FONT_HERSHEY_SIMPLEX, 0.45, (255, 215, 0), 1)
            if stats.get("done", False):
                status_text, status_col = "COMPLETE", (50, 255, 80)
            elif stats.get("paused", False):
                status_text, status_col = "PAUSED", (255, 220, 60)
            elif is_train:
                status_text, status_col = "TRAINING", (255, 120, 50)
            else:
                status_text, status_col = "STANDBY", (180, 180, 180)
            cv2.putText(frame, f"FPGA Core: {status_text}", (sx, 310), cv2.FONT_HERSHEY_SIMPLEX, 0.40, status_col, 1)
            mode_text = "EXPLOIT" if eps <= 0.20 else ("EXPLORE" if eps >= 0.60 else "BALANCED")
            mode_col  = (80, 240, 100) if mode_text == "EXPLOIT" else ((255, 70, 70) if mode_text == "EXPLORE" else (255, 220, 60))
            cv2.putText(frame, f"Policy:   {mode_text}", (sx, 340), cv2.FONT_HERSHEY_SIMPLEX, 0.40, mode_col, 1)
            cv2.putText(frame, "Q Heatmap: Low -> High", (sx, 390), cv2.FONT_HERSHEY_SIMPLEX, 0.35, (160, 180, 200), 1)
            for bar_i in range(160):
                c_val = self._get_heat_color(-2.0 + (bar_i / 160.0) * 102.0)
                frame[405:415, sx + bar_i] = c_val
        return frame

class EthernetVisualizer:
    def __init__(self, driver: RLHardwareDriver, width=640, height=480, fps=12, enable_hdmi=False):
        self.driver = driver
        self.width = width
        self.height = height
        self.fps = fps
        self.renderer = GridRenderer(width, height)
        if enable_hdmi:
            print("[Notice] This overlay has no HDMI output; streaming into the notebook only.")

    def render_current_frame(self):
        stats = self.driver.get_status()
        q_table = self.driver.read_q_table()
        maze_mask = self.driver.read_maze()
        return self.renderer.render(
            q_table=q_table,
            agent_row=stats["agent_row"],
            agent_col=stats["agent_col"],
            maze_mask=maze_mask,
            stats=stats
        ), stats

    def run_live_stream(self, duration_sec=10.0, fps=None):
        target_fps = fps or self.fps
        frame_interval = 1.0 / target_fps
        maze_mask = self.driver.read_maze()
        frame, stats = self.render_current_frame()

        if HAS_IPYTHON:
            try:
                jpeg_data = encode_frame_to_jpeg(frame)
                clear_output(wait=True)
                display(IPImage(data=jpeg_data))
            except Exception as e:
                print(f"[Ethernet Visualizer] Note: In-cell display initialization: {e}")

        start_time = time.time()
        frame_count = 0
        print(f"[Ethernet Visualizer] Streaming live learning dynamics over Ethernet ({duration_sec:.1f}s)...")
        init_stats = self.driver.get_status()
        start_goals = init_stats.get("total_goals", 0)
        goal_reached_frame = None

        while (time.time() - start_time) < duration_sec:
            loop_start = time.time()
            stats = self.driver.get_status()
            q_table = self.driver.read_q_table()
            row = stats["agent_row"]
            col = stats["agent_col"]
            cur_goals = stats.get("total_goals", 0)


            if cur_goals > start_goals or (row == 7 and col == 7) or stats.get("done", False):
                st_goal = dict(stats)
                st_goal["done"] = True
                st_goal["training"] = False
                goal_frame = self.renderer.render(
                    q_table=q_table,
                    agent_row=7,
                    agent_col=7,
                    maze_mask=maze_mask,
                    stats=st_goal
                )
                goal_reached_frame = goal_frame
                if HAS_IPYTHON:
                    try:
                        clear_output(wait=True)
                        display(IPImage(data=encode_frame_to_jpeg(goal_frame, quality=90)))
                    except Exception:
                        pass
                print(f"[Ethernet Visualizer] GOAL REACHED! Target found in {stats['best_steps']} steps! Total goals: {cur_goals}")
                time.sleep(1.0)
                break

            frame = self.renderer.render(
                q_table=q_table,
                agent_row=row,
                agent_col=col,
                maze_mask=maze_mask,
                stats=stats
            )
            if HAS_IPYTHON:
                try:
                    jpeg_data = encode_frame_to_jpeg(frame)
                    clear_output(wait=True)
                    display(IPImage(data=jpeg_data))
                except Exception:
                    pass
            frame_count += 1
            elapsed = time.time() - loop_start
            sleep_time = max(0.001, frame_interval - elapsed)
            time.sleep(sleep_time)

        final_frame = goal_reached_frame if goal_reached_frame is not None else self.render_current_frame()[0]
        if HAS_IPYTHON:
            try:
                clear_output(wait=True)
                display(IPImage(data=encode_frame_to_jpeg(final_frame, quality=90)))
            except Exception:
                pass
        print(f"[Ethernet Visualizer] Live stream finished ({frame_count} frames streamed over Ethernet).")

    def run_live_visualization(self, duration_sec=10.0):
        return self.run_live_stream(duration_sec=duration_sec)

    def close(self):
        pass

JupyterLiveVisualizer = EthernetVisualizer
HDMIVisualizer = EthernetVisualizer
