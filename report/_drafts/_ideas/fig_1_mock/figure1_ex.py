"""
Mock Figure 1: Event-Study Style Plot
Regulatory Speed (Priority vs Standard Review) and Post-Approval Supply

This script generates simulated data to visualize what Figure 1
in the thesis could look like.
"""

import numpy as np
import matplotlib.pyplot as plt

# -----------------------------
# 1. Create mock event-time data
# -----------------------------
np.random.seed(42)

# Event time: quarters relative to approval
quarters = np.arange(-8, 13)

# Simulated post-approval growth patterns
priority_growth = np.where(
    quarters >= 0,
    2 + 0.6 * quarters + np.random.normal(0, 0.3, len(quarters)),
    np.random.normal(0.05, 0.05, len(quarters))
)

standard_growth = np.where(
    quarters >= 0,
    2 + 0.35 * quarters + np.random.normal(0, 0.3, len(quarters)),
    np.random.normal(0.05, 0.05, len(quarters))
)

# Simulated confidence intervals
priority_ci = 0.6 + 0.05 * np.abs(quarters)
standard_ci = 0.6 + 0.05 * np.abs(quarters)

# -----------------------------
# 2. Plot the event study figure
# -----------------------------
plt.figure(figsize=(10, 6))

# Priority Review line
plt.plot(quarters, priority_growth, label="Priority Review", linewidth=2)
plt.fill_between(
    quarters,
    priority_growth - priority_ci,
    priority_growth + priority_ci,
    alpha=0.2
)

# Standard Review line
plt.plot(quarters, standard_growth, label="Standard Review", linewidth=2)
plt.fill_between(
    quarters,
    standard_growth - standard_ci,
    standard_growth + standard_ci,
    alpha=0.2
)

# Vertical line at approval
plt.axvline(x=0, linestyle="--")

# Labels and formatting
plt.title("Figure 1: Post-Approval Distribution Growth by FDA Review Classification")
plt.xlabel("Quarters Relative to FDA Approval")
plt.ylabel("Mock ARCOS Grams per 100K Population")
plt.legend()
plt.tight_layout()

# Save figure
plt.savefig("figure1_mock.png", dpi=300)
plt.show()

print("Mock Figure 1 saved as 'figure1_mock.png'")
