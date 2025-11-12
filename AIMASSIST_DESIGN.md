# 🎯 Symphony Hub - Next-Gen Aim Assist Design Document

## 📋 Executive Summary

This document outlines the **technical design and architecture** of the Symphony Hub Next-Gen Aim Assist system—a top-tier predictive tracking solution implementing Kalman filtering, adaptive latency compensation, and jump trajectory prediction.

---

## 🏗️ System Architecture

### High-Level Component Diagram

```
┌─────────────────────────────────────────────────────────┐
│              AimAssist Module (Main API)                │
│  • Target Management                                    │
│  • Update Loop Coordination                             │
│  • Configuration & Quality Control                      │
└─────────────┬───────────────────────────────────────────┘
              │
     ┌────────┴────────┐
     │                 │
     ▼                 ▼
┌─────────┐      ┌──────────────┐
│Movement │◄─────┤  Prediction  │
│ Tracker │      │    Engine    │
└────┬────┘      └──────┬───────┘
     │                  │
     │           ┌──────┴────────┐
     │           │               │
     │           ▼               ▼
     │      ┌────────┐     ┌─────────┐
     │      │Kalman  │     │   EMA   │
     │      │Filter  │     │Predictor│
     │      └────────┘     └─────────┘
     │
     ├────────────────────────────────┐
     │                                │
     ▼                                ▼
┌──────────┐                   ┌────────────┐
│  Jump    │                   │  Latency   │
│Predictor │                   │Compensator │
└─────┬────┘                   └─────┬──────┘
      │                              │
      └──────────────┬───────────────┘
                     │
                     ▼
              ┌────────────┐
              │    Aim     │
              │   Solver   │
              └────────────┘
```

---

## 🧩 Core Components

### 1. **PredictionEngine**

**Purpose**: State estimation and position/velocity prediction

**Algorithms**:

#### a) Kalman Filter (Primary)
- **State Vector**: `[x, y, z, vx, vy, vz]` (position + velocity)
- **Process Model**: Constant velocity model with process noise
- **Measurement Model**: Position-only measurements with measurement noise
- **Update Rate**: Every frame (60+ Hz)
- **Prediction**: Uses state transition matrix to extrapolate future states

**Mathematics**:
```
Prediction Step:
  x_k = F * x_{k-1}
  P_k = F * P_{k-1} * F^T + Q

Update Step:
  K = P_k * H^T * (H * P_k * H^T + R)^{-1}  (Kalman Gain)
  x_k = x_k + K * (z_k - H * x_k)           (State update)
  P_k = (I - K * H) * P_k                   (Covariance update)

Where:
  F = State transition matrix
  P = Error covariance
  Q = Process noise covariance
  R = Measurement noise covariance
  H = Measurement matrix
  z_k = Measurement at time k
```

**Configuration**:
- `processNoise = 1e-2`: Trust motion model moderately
- `measurementNoise = 1e-1`: Trust measurements more than prediction

#### b) EMA Predictor (Fallback)
- **Algorithm**: Exponential Moving Average with linear extrapolation
- **Formula**: `predicted_pos = smoothed_pos + smoothed_vel * dt`
- **Smoothing**: `smoothed_vel = α * new_vel + (1-α) * old_vel`
- **Alpha**: 0.6 (60% new data, 40% history)

**Use Cases**:
- Low-end hardware (performance priority)
- Kalman initialization failures
- Extremely erratic movement

---

### 2. **LatencyCompensator**

**Purpose**: Network latency detection and prediction time adjustment

**Features**:

#### Ping Estimation
1. **Stats-based**: Reads from Roblox Stats service
2. **Manual**: User-provided RTT measurements
3. **Smoothing**: Moving average over N samples (default: 8)

#### Latency Profiles
```lua
Low Latency (<50ms):
  extrapolationFactor = 0.4
  Assumption: Minimal prediction needed

Medium Latency (50-150ms):
  extrapolationFactor = 0.5
  Standard compensation

High Latency (>150ms):
  extrapolationFactor = 0.6
  Aggressive extrapolation
```

#### Extrapolation Calculation
```lua
extrapolationTime = (smoothedPing / 1000) * extrapolationFactor
extrapolationTime = clamp(extrapolationTime, 0, maxExtrapolation)
```

#### Adaptive Adjustment
- **Fast targets** (>30 studs/s): +15% extrapolation
- **Very fast targets** (>50 studs/s): +25% extrapolation

---

### 3. **JumpPredictor**

**Purpose**: Predict airborne trajectories using projectile motion physics

**Physics Model**:

#### Vertical Motion (Y-axis)
```
y(t) = y₀ + v_y₀ * t - 0.5 * g * t²
v_y(t) = v_y₀ - g * t

Where:
  g = 196.2 studs/s² (Roblox gravity)
  y₀ = initial height
  v_y₀ = initial vertical velocity
```

#### Horizontal Motion (X, Z axes)
```
x(t) = x₀ + v_x₀ * t  (constant velocity)
z(t) = z₀ + v_z₀ * t
```

#### Key Calculations

**Time to Apex**:
```lua
t_apex = v_y₀ / g
```

**Apex Height**:
```lua
h_max = y₀ + (v_y₀²) / (2 * g)
```

**Landing Time**:
```lua
t_fall = sqrt(2 * (h_max - h_ground) / g)
t_total = t_apex + t_fall
```

**Landing Position**:
```lua
landing_pos = start_pos + horizontal_velocity * t_total
```

#### Jump Detection
- **Grounded → Airborne**: Jump start detected
- **Humanoid state**: Checks for Jumping, Freefall, Flying states
- **Vertical velocity**: Must be positive to confirm jump

---

### 4. **MovementTracker**

**Purpose**: Real-time target state sampling and validation

**Tracked Data**:
- Position (HumanoidRootPart)
- Velocity (calculated from position delta)
- Grounded state (Humanoid state)
- Sample history (last N samples)

**Velocity Calculation**:
```lua
instantaneous_vel = (current_pos - last_pos) / dt
smoothed_vel = 0.7 * instantaneous_vel + 0.3 * last_vel
```

**Target Validation**:
- Player exists
- Character exists
- RootPart exists
- Humanoid alive (health > 0)

**Grounded State Detection**:
```lua
Grounded states:
  - Running, RunningNoPhysics
  - Landed, GettingUp
  - Climbing, Seated

Airborne states:
  - Jumping, Freefall
  - Flying, Physics
```

---

### 5. **AimSolver**

**Purpose**: Convert predicted positions to camera aim adjustments

**Features**:

#### FOV Constraints
```lua
angle = acos(cameraLookVector · toTarget)
if angle > maxFOV then
  -- Target outside FOV, reject
end
```

#### Dead Zone
```lua
if angle < deadZone then
  -- Already on target, no adjustment
end
```

#### Smoothing

**Lerp-based Smoothing**:
```lua
new_aim = lerp(current_aim, target_aim, lerpFactor)
```

**Angular Rate Limiting**:
```lua
max_angle_this_frame = maxAnglePerSec * dt
if angle_difference > max_angle_this_frame then
  lerp_factor = max_angle_this_frame / angle_difference
  new_aim = lerp(current_aim, target_aim, lerp_factor)
end
```

#### Target Lead (Projectile Weapons)
```lua
time_to_hit = distance / projectile_speed
lead_position = target_pos + target_vel * time_to_hit
```

---

## ⚙️ Quality Presets

### Low Quality
- **Algorithm**: EMA only
- **Lerp**: 0.08 (slower)
- **Max Angle/Sec**: 600°
- **Use Case**: Low-end devices, performance priority

### Balanced Quality (Default)
- **Algorithm**: Kalman with EMA fallback
- **Lerp**: 0.12 (moderate)
- **Max Angle/Sec**: 720°
- **Use Case**: Most players, optimal balance

### High Quality
- **Algorithm**: Kalman only (no fallback)
- **Lerp**: 0.15 (faster)
- **Max Angle/Sec**: 900°
- **Use Case**: High-end devices, accuracy priority

---

## 🔄 Main Update Loop

```lua
function AimAssist:update(dt)
  1. Validate target (exists, alive)
  2. Update MovementTracker → sample current state
  3. Update LatencyCompensator → estimate ping
  4. Update JumpPredictor → check airborne state
  5. Update PredictionEngine → Kalman/EMA update
  
  6. Calculate extrapolation time (ping-based)
  
  7. IF jumping THEN
       predicted_pos = JumpPredictor:predict()
     ELSE
       predicted_pos = PredictionEngine:predict()
     END
  
  8. AimSolver:computeAim(predicted_pos)
  
  9. Return aim vector + camera CFrame
end
```

**Frame Budget**: <1ms per frame (target: 0.3-0.5ms)

---

## 📊 Performance Metrics

### Targets
- **Frame Time**: <1ms (avg: 0.3-0.5ms)
- **CPU Usage**: <5% single core
- **Memory**: <5MB
- **Prediction Accuracy**: 90%+ hit rate at 50ms ping

### Optimization Strategies
1. **Lazy Computation**: Only predict when locked
2. **Cached Services**: Service access cached
3. **Efficient Math**: Vector operations optimized
4. **Quality Scaling**: Adaptive algorithm selection

---

## 🛡️ Safety & Stability

### Input Validation
- All external inputs validated (type, range)
- NaN/Inf checks on all calculations
- Nil-safe operations throughout

### Error Handling
- Graceful fallback: Kalman → EMA
- Target validation every frame
- Component isolation (no cascading failures)

### Bounds Checking
- Velocity clamping: Max 1000 studs/s
- Prediction time: Max 0.35s
- FOV: 0° - 180°
- Ping: 0ms - 5000ms

---

## 🔧 Configuration API

### Runtime Tuning
```lua
aimAssist:setQuality("balanced")
aimAssist:setParam("lerp", 0.15)
aimAssist:setParam("maxFOV", 90)
aimAssist:setParam("deadZone", 2)
aimAssist:setParam("maxAnglePerSec", 800)
aimAssist:setParam("extrapolationFactor", 0.55)
```

### Manual Ping Override
```lua
aimAssist:manualPingUpdate(roundTripTime)
```

---

## 🐛 Debug & Diagnostics

### Debug Info
```lua
local info = aimAssist:getDebugInfo()
print(info.predictor.predictor)  -- "kalman" or "ema"
print(info.latency.currentPing)  -- "50.5 ms"
print(info.jumpPredictor.isJumping)  -- true/false
```

### Performance Stats
```lua
local stats = aimAssist:getPerformanceStats()
print(stats.avgFrameTime)  -- Average processing time
print(stats.fps)           -- Effective prediction FPS
```

### Console Output
```lua
aimAssist:printDebugInfo()  -- Formatted debug output
```

---

## 🧪 Testing & Tuning

### Test Scenarios
1. **Linear Movement**: Straight-line target at constant velocity
2. **Strafing**: Side-to-side zigzag pattern
3. **Jumping**: Repeated jump cycles
4. **Fast Movement**: Sprint + jump combinations
5. **High Latency**: Simulated 150ms+ ping

### Tuning Parameters

**For Accuracy**:
- Increase `processNoise` (trust measurements more)
- Decrease `lerpFactor` (smoother aim)
- Increase `maxAnglePerSec` (faster tracking)

**For Smoothness**:
- Decrease `lerpFactor` (slower aim)
- Decrease `maxAnglePerSec` (limited speed)
- Increase `deadZone` (less micro-adjustments)

**For Fast Targets**:
- Increase `extrapolationFactor`
- Increase `maxExtrapolation`
- Use "high" quality preset

---

## 📈 Future Enhancements

### Potential Upgrades
1. **Neural Predictor**: ML-based movement pattern learning
2. **Multi-Target Tracking**: Simultaneous target management
3. **Weapon-Specific Tuning**: Per-weapon configuration profiles
4. **Advanced Physics**: Wind, gravity variations
5. **Replay System**: Record and analyze prediction accuracy

---

## 📚 References

- Kalman, R.E. (1960). "A New Approach to Linear Filtering and Prediction Problems"
- Welch & Bishop (2006). "An Introduction to the Kalman Filter"
- Roblox Physics Documentation
- Game Networking Best Practices

---

## 📝 Version History

**v1.0.0** (2025-01-XX)
- Initial release
- Kalman Filter + EMA implementation
- Adaptive latency compensation
- Jump trajectory prediction
- Quality presets
- Debug system

---

**Designed for Symphony Hub © 2025**  
**Top-Tier Competitive Aim Assist**
