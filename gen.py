import numpy as np
import random
import matplotlib.pyplot as plt
import game, perceptron, arcade
import pickle
from pathlib import Path

class GA:
    def __init__(self, n, p, mp, rp, fitness_func):
        # number of entries in a genotype
        self.n = n
        # population size
        self.p = p
        # mutation probability
        self.mp = mp
        # recombination probability
        self.rp = rp
        self.fitness_func = fitness_func
        self.pop = np.random.uniform(-1, 1, size=(p, n))
        self.tournament_count = 0
        self.scores = []
        self.averages = []
        self.generations = []

    def mutate(self, genotype):
        for bit in range(self.n):
            mutate_ = random.uniform(0, 1)

            if mutate_ <= self.mp:
                genotype[bit] += np.random.uniform(-1, 1)

                if genotype[bit] > 1:
                    genotype[bit] = 1
                if genotype[bit] < -1:
                    genotype[bit] = -1

        return genotype

    def recombination(self, winner, loser):
        for i in range(self.n):
            recomb_ = np.random.uniform(0, 1)

            if recomb_ <= self.rp:
                loser[i] = winner[i]

        return loser

    def tournament(self):
        geno1 = random.randint(0, self.p-1)
        geno2 = random.randint(0, self.p-1)

        while geno1 == geno2:
            geno1 = random.randint(0, self.p-1)
            geno2 = random.randint(0, self.p-1)

        fitness1 = self.fitness_func(self.pop[geno1])
        fitness2 = self.fitness_func(self.pop[geno2])

        self.scores.append(fitness1)
        self.scores.append(fitness2)

        if fitness1 > fitness2:
            winner = self.pop[geno1]
            loser = self.pop[geno2]
        if fitness2 >= fitness1:
            winner = self.pop[geno2]
            loser = self.pop[geno1]

        loser = self.mutate(loser)
        loser = self.recombination(winner, loser)

        self.pop[geno1] = winner
        self.pop[geno2] = loser

        self.tournament_count += 1

        if self.tournament_count >= self.p // 2:
            self.averages.append(sum(self.scores) / len(self.scores))
            self.generations.append(self.pop)
            self.save_generation()
            self.scores = []
            self.tournament_count = 0

    def load_generation(self):
        file_name = "generations.save"

        save_file = Path(file_name)

        if save_file.is_file():
            with open(file_name, "rb") as save:
                self.generations = pickle.load(save)
                self.pop = self.generations[len(self.generations) - 1]
                save.close()
                

        file_name = "averages.save"
        save_file = Path(file_name)

        if save_file.is_file():
            with open(file_name, "rb") as save:
                self.averages = pickle.load(save)
                print(self.averages)
                save.close()


    def save_generation(self):
        print(f'Saved generation {len(self.generations)}')
        file_name = "generations.save"

        with open(file_name, "wb") as save:
            pickle.dump(self.generations, save)
            save.close()

        file_name = "averages.save"

        with open(file_name, "wb") as save:
            pickle.dump(self.averages, save)
            save.close()

    def get_best_geno(self):
        best_val = 0
        best_fit = None
        for i in range(self.p):
            val = self.fitness_func(self.pop[i])
            if val > best_val:
                best_val = val
                best_fit = self.pop[i]

        return best_fit


def fit_func(genotype):
    agent = perceptron.MultilayerPerceptron([genotype[0], genotype[1], genotype[2], genotype[3]], [genotype[4], genotype[5], genotype[6], genotype[7]])
    window = game.Window()
    window.setup(agent)
    arcade.run()

    print(window.score)
    return window.score

gen_alg = GA(8, 20, .2, .2, fit_func)
gen_alg.load_generation()
for i in range(200):
    gen_alg.tournament()
