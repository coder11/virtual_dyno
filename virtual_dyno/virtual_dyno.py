import numpy as np
import matplotlib
import matplotlib.pyplot as plt
from scipy.constants import pi

matplotlib.use("Qt5Agg")

# Initial Parameters
motor_model = 'TorqueBoards 6355 190 Kv'
Kv = 190  # [rpm/V]
current = 2 * 60  # [A]
Kt = 9.55 / Kv  # [N*m/A]
pole_pairs = 7
phase_resistance = 0.0177  # [ohms]

# Measured Values
erpm_measured = np.array([18220, 42830])  # [erpm]
rpm_measured = erpm_measured / pole_pairs  # [rpm]
current_measured = np.array([0.29, 0.48])  # [A]

# Calculated Peak Values and Constants
voltage = 84  # [V]
peak_rpm = voltage * Kv  # [rpm]
peak_torque = current * Kt  # [N*m]
peak_dutycycle = 0.95  # [%]
Km = Kt / np.sqrt(1.5 * phase_resistance)

# RPM and Torque Vectors
rpm_vector = np.linspace(0, peak_rpm, int(peak_rpm / 10))  # [rpm]
torque_vector = np.linspace(0, peak_torque, int(peak_torque * 100))  # [N*m]

# Core Losses (linear fit)
fit_params = np.polyfit(rpm_measured, current_measured, 1)
core_loss_torque_vector = fit_params[1] + fit_params[0] * rpm_vector  # [N*m]
core_loss_power_vector = core_loss_torque_vector * rpm_vector / (60 * 2 * pi)

# Core Loss Power Matrix
core_loss_power_matrix = np.tile(core_loss_power_vector, (len(torque_vector), 1))

# Total Torque and Motor Current Matrix
total_torque_matrix = np.zeros((len(torque_vector), len(rpm_vector)))
motor_current_matrix = np.zeros((len(torque_vector), len(rpm_vector)))

for i in range(len(torque_vector)):
    for k in range(len(rpm_vector)):
        total_torque_matrix[i, k] = torque_vector[i] + core_loss_torque_vector[k]
        motor_current_matrix[i, k] = total_torque_matrix[i, k] / Kt

# Output Power Matrix
output_power_matrix = np.outer(torque_vector, rpm_vector) * 2 * pi / 60

# Copper Loss Power Matrix
copper_loss_power_matrix = np.zeros((len(torque_vector), len(rpm_vector)))
for i in range(len(torque_vector)):
    for k in range(len(rpm_vector)):
        copper_loss_power_matrix[i, k] = 1.5 * phase_resistance * (motor_current_matrix[i, k]) ** 2

# Total Loss Power and Efficiency Matrix
total_loss_power_matrix = core_loss_power_matrix + copper_loss_power_matrix
total_power_matrix = total_loss_power_matrix + output_power_matrix
motor_efficiency_matrix = 100 * output_power_matrix / total_power_matrix

# Required Voltage Matrix
required_voltage_matrix = np.zeros((len(torque_vector), len(rpm_vector)))
for i in range(len(torque_vector)):
    for k in range(len(rpm_vector)):
        required_voltage_matrix[i, k] = (rpm_vector[k] / Kv + phase_resistance * motor_current_matrix[i, k]) / peak_dutycycle

# Plotting function to organize plots in a grid
def plot_contour(ax, x, y, z, title, c_label, levels, voltages, currents):
    # Fill contours
    contour_plot = ax.contourf(x, y, z, levels=levels, cmap='jet', extend='both')
    ax.set_title(title)
    ax.set_xlabel('Speed [rpm]')
    ax.set_ylabel('Torque [N m]')
    cbar = plt.colorbar(contour_plot, ax=ax, label=c_label)

    # Voltage and Current Contours
    v_contours = ax.contour(x, y, required_voltage_matrix, levels=voltages, colors='white', linestyles='-')
    ax.clabel(v_contours, fmt=lambda x: f"{x:.0f} [V]", fontsize=8)

    c_contours = ax.contour(x, y, motor_current_matrix, levels=currents, colors='white', linestyles='--')
    ax.clabel(c_contours, fmt=lambda x: f"{x:.0f} [A]", fontsize=8)

    # Add contour lines that match the filled contours
    z_contours = ax.contour(x, y, z, levels=levels, colors='k', linewidths=0.5)  # Use the same levels
    ax.clabel(z_contours, inline=True, fontsize=8, fmt="%.1f")  # Labeling the contour lines

# Define plot levels
efficiency_levels = np.arange(0, 101, 5)
loss_levels = np.linspace(0, np.max(total_loss_power_matrix), 20)
output_power_levels = np.linspace(0, np.max(output_power_matrix), 20)

# Create subplots in a 2x3 grid
fig, axs = plt.subplots(2, 3, figsize=(18, 12))
fig.suptitle(f"Motor Performance Maps - {motor_model}")

voltages = [22, 37, 44, 52, 60, 67, 74]
currents = [current * x for x in [0.25, 0.5, 0.75, 1]]

# Plot each map in its respective subplot
plot_contour(axs[0, 0], rpm_vector, torque_vector, motor_efficiency_matrix, "Efficiency Map", "Efficiency [%]", efficiency_levels, 
             voltages, currents)
plot_contour(axs[0, 1], rpm_vector, torque_vector, total_loss_power_matrix, "Total Losses", "Losses [W]", loss_levels, 
             voltages, currents)
plot_contour(axs[0, 2], rpm_vector, torque_vector, copper_loss_power_matrix, "Copper Losses", "Copper Losses [W]", loss_levels, 
             voltages, currents)
plot_contour(axs[1, 0], rpm_vector, torque_vector, core_loss_power_matrix, "Core Losses", "Core Losses [W]", loss_levels, 
             voltages, currents)
plot_contour(axs[1, 1], rpm_vector, torque_vector, output_power_matrix, "Output Power", "Output Power [W]", output_power_levels, 
             voltages, currents)

# Hide the empty subplot (bottom right in 2x3 grid)
axs[1, 2].axis('off')

plt.tight_layout(rect=[0, 0, 1, 0.96])  # Adjust layout to fit the figure title
plt.show()
