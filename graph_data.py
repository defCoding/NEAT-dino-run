import sys
import pickle
import matplotlib
import matplotlib.pyplot as plt

from pathlib import Path

file_name = sys.argv[1]
save_file = Path(file_name)
averages = []

if save_file.is_file():
    with open(file_name, "rb") as save:
        averages = pickle.load(save)

plt.plot(averages)
plt.ylabel("Average Time")
plt.show()
