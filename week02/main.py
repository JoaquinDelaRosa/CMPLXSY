import matplotlib.pyplot as plt
import matplotlib.animation as animation

import numpy as np

class CellularAutomata:
    def __init__(self, length, width):
        self.lattice = np.zeros(shape=(length, width))
        self.shape = self.lattice.shape
        self.states = [0, 1]

    def initialize_random(self):
        self.lattice = np.random.choice(self.states, self.shape[0] * self.shape[1]).reshape(*self.shape)


    def get_neighborhood(self, lattice : np.ndarray, x, y) -> np.ndarray:
        (l, w) = lattice.shape
        return np.array([lattice[(x + i) % l][(y + j) % w] for i in range(-1, 1 + 1) for j in range(-1, 1 + 1) if not (i == 0 and j == 0)])

    def update(self):
        self.buffer = np.ndarray.copy(self.lattice)
        shape = self.buffer.shape

        for x in range(shape[0]):
            for y in range(shape[1]):
                curr = self.buffer[x][y]
                neighbors = self.get_neighborhood(self.buffer, x, y)
                alive_count = neighbors.sum()

                if curr == 0:
                    if alive_count == 3:
                        self.lattice[x][y] = 1
                    else:
                        self.lattice[x][y] = 0
                else:
                    if alive_count < 2:
                        self.lattice[x][y] = 0
                    elif alive_count > 3:
                        self.lattice[x][y] = 0
                    else:
                        self.lattice[x][y] = 1 

    def __str__(self):
        return str(self.lattice)


class Renderer:
    def __init__(self, automata : CellularAutomata):
        self.automata = automata 
    
    def render(self, steps, delta = 1000):
        def animate(frame, img, automata : CellularAutomata):
            automata.update()
            img.set_data(automata.lattice)
            return img
        
        fig, ax = plt.subplots()
        img = ax.matshow(self.automata.lattice, cmap='gray')
        anim = animation.FuncAnimation(fig, animate, fargs=(img, self.automata), frames=steps, interval=delta)
        plt.show() 

def main():
    automata : CellularAutomata = CellularAutomata(200, 200)
    automata.initialize_random()

    renderer : Renderer = Renderer(automata)

    STEPS = 100
    DELTA = 0.1
    renderer.render(STEPS, DELTA)

if __name__ == "__main__":
    main()    

