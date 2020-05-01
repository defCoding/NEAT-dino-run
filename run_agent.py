import sys
import pickle
from pathlib import Path
import game
import arcade
import perceptron

file_name = sys.argv[1]
save_file = Path(file_name)
genotype = []

if save_file.is_file():
    with open(file_name, "rb") as save:
        genotype = pickle.load(save)

agent = perceptron.MultilayerPerceptron([genotype[0], genotype[1], genotype[2], genotype[3]], [genotype[4], genotype[5], genotype[6], genotype[7]])

window = game.Window()
window.setup(agent, False)
arcade.run()
