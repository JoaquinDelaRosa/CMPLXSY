## Model Specifications

Lattice: Two dimensional, square lattice. It is toroidal (i.e., the top wraps to the bottom and the left wraps to the right.)

Neighborhood: A generalization of the Moore Neighborhood. We look at a (2r + 1) by (2r + 1) region around a cell.

States: 0,1 (dead or alive).

Rules Function.
Let K be a kernel the size of the neighborhood (2r + 1 by 2r + 1).
    K has been normalized so that the sum of all values in the kernel is 1.

    N be the neighborhood around a cell (2r + 1 by 2r + 1).

Apply the convolution
u = K * N

The transition rules are determined by u and the state of the cell
if cell is dead:
    if u > 2/9 and u <3/9:
        cell becomes alive
    else:
        cell stays dead

if cell is alive:
    if u < 3/9 or u > 4/9: 
        cell becomes dead
    else:
        cell stays alive

## Analogy to Real Life

The Cellular Automata serves as a generalization to the Game Of Life. For one, we use a larger neighborhood, which means 
that more cells can affect a particular cell (i.e., the system is more interconnected). At the same time, because there are more neighbors, each individual cell may have a lower impact on a particular cell.

The result is, for especially large kernels, 