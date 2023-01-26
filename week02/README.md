## What is It? 
The model serves as an extension to Conway's Game of Life. Abstractly, it serves to model the trends in the growth and death of entities under the assumption that
1. Each entity's survival is dependent on the survival of its neighbors. We may think of this as entities sharing resources.
2. The weights of what each neighbor "contribtes" to the survival of the current cell is not necessarily the same, but we may think of it as sampled from a Gaussian distribution to reflect inherent noisiness in the real world.

## How it Works?
The model is a Cellular Automata that is defined as follows:

**Lattice**: Two dimensional, square lattice. It is toroidal (i.e., the top wraps to the bottom and the left wraps to the right.)

**Neighborhood**: A generalization of the Moore Neighborhood. We look at a (2r + 1) by (2r + 1) region around a cell.

**States**: 0,1 (dead or alive).

**Rules Function**.
Let 
```
K be a kernel the size of the neighborhood (shape: 2r + 1 by 2r + 1). 
K is initialized usng Gaussian Noise.
K has been normalized so that the sum of all values in the kernel is 1.
    
N be the values of the neighborhood around a cell (shape: 2r + 1 by 2r + 1).
```

Apply the convolution
```
u = K * N
```

The transition rules are determined by u and the state of the cell
```
if u < p:
    cell becomes dead
if p < u < q: 
    cell becomes alive
if q < u
    cell becomes dead
```

**Hyperparameters**
```
r is the size of the Moore Neighborhood to use (specifically half the side-length of the squae defining the neighborhood)
p is the **underpopulation threshold**. If the function evaluates to anything below this, the cell dies.
q is the **overpopulation threshold**. If the function evaluates to anything above this, the cell dies.
```

## How To Use It?
Open the Python File in your favorite IDE and watch the animation play out.

Parameters may be set within the Cellular Automata class. 

## Things to Notice?
Certain "macro-organisms" (analogous to Game of Life's gliders, and Gosper guns) may emerge from different settings of r, p and q. These organisms tend to move about across the grid. Generally, these organisms appear to move in a certaind direction (until they collide, merge or disrupt another organism in its path).

Some settings of r, p and q may also result in no organisms being alive after the next step. This may indicate that these parameters are "too harsh" for any organism in our model to live in.

## Things to Try?
Play around with r, p and q and set them to different values.

## Extending the Model
Each cell may have its own convolution kernel that corresponds to it.

## Related Models
This model was inspired by the Game of Life [here](https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life) and its extension Lenia [here](https://chakazul.github.io/lenia.html)
