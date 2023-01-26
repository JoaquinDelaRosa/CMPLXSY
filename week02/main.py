import matplotlib.pyplot as plt
import matplotlib.animation as animation

import numpy as np

class CellularAutomata:
    def __init__(self, length, width):
        self.lattice = np.zeros(shape=(length, width))
        self.shape = self.lattice.shape
        self.states = [0, 1]

        self.n_radius = 5
        self.kernel = self.get_kernel()
        self.p = 0.2
        self.q = 0.4


    def initialize_random(self):
        self.lattice = np.random.choice(self.states, self.shape[0] * self.shape[1]).reshape(*self.shape)


    def get_neighborhood(self, lattice : np.ndarray, x, y) -> np.ndarray:
        (l, w) = lattice.shape
        return np.array([lattice[(x + i) % l][(y + j) % w] for i in range(-self.n_radius, self.n_radius + 1) 
            for j in range(-self.n_radius, self.n_radius + 1)])

    def get_kernel(self):
        kernel =np.random.uniform(0, 1, size=(2 * self.n_radius + 1) * (2 * self.n_radius + 1))
        return kernel / np.sum(kernel)
    
    def update(self):
        self.buffer = np.ndarray.copy(self.lattice)
        shape = self.buffer.shape

        for x in range(shape[0]):
            for y in range(shape[1]):
                neighbors = self.get_neighborhood(self.buffer, x, y)
                u = np.dot(neighbors, self.kernel)

                if u > self.p and u < self.q:
                    self.lattice[x][y] = 1
                else:
                    self.lattice[x][y] = 0

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
    automata : CellularAutomata = CellularAutomata(100, 100)
    automata.initialize_random()

    print ("Kernel Used \n", automata.kernel)

    renderer : Renderer = Renderer(automata)

    STEPS = 100
    DELTA = 0.1
    renderer.render(STEPS, DELTA)

if __name__ == "__main__":
    main()    