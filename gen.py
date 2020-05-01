import numpy as np
import random
import matplotlib.pyplot as plt
import game, perceptron, arcade
import pickle
from pathlib import Path
import signal
from contextlib import contextmanager

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
        self.best_in_generation = (None, 0)
        self.num_best_saved = 1 # Number of best in generation saved.

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

        winner = (geno1, fitness1) if fitness1 > fitness2 else (geno2, fitness2)
        loser = (geno2, fitness2) if fitness2 <= fitness1 else (geno1, fitness1)

        # Update best in generation.
        if winner[1] > self.best_in_generation[1]:
            self.best_in_generation = winner

        self.pop[loser[0]] = self.mutate(self.pop[loser[0]])
        self.pop[loser[0]] = self.recombination(self.pop[winner[0]], self.pop[loser[0]])

        self.tournament_count += 1

        if self.tournament_count >= self.p // 2:
            self.averages.append(sum(self.scores) / len(self.scores))
            self.generations.append(self.pop)
            self.save_generation()
            self.scores = []
            self.tournament_count = 0

            if self.num_best_saved ** 2 == len(self.generations):
                print(f'Saved best in generation with score {self.best_in_generation[1]}.')
                file_name = f'best_in_gen_{self.num_best_saved ** 2}.save'

                with open(file_name, "wb") as save:
                    pickle.dump(self.pop[self.best_in_generation[0]], save)
                    save.close()

                self.num_best_saved += 1

            self.best_in_generation = (None, 0)

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
    window.setup(agent, False)
    arcade.run()

    print(window.score)
    return window.score

@contextmanager
def timeout(time):
    signal.signal(signal.SIGALRM, raise_timeout)

    signal.alarm(time)

    try:
        yield
    except TimeoutError:
        pass
    finally:
        signal.signal(signal.SIGALRM, signal.SIG_IGN)

def raise_timeout(signum, frame):
    raise TimeoutError


gen_alg = GA(8, 20, .2, .2, fit_func)
gen_alg.load_generation()
for i in range(360):
    gen_alg.tournament()
