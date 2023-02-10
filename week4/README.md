## What Is It? 

The following model is a predator-prey model which models the interactions between cats and mice in a grassland environment.

The environment consists of food (in this case grass) which grows at a fixed number of ticks. Prey entities (in this case, mice) can roam the environemnt in random 
manner to feed on the grass, and Predator entities (in this case, cats) can do the same and feed on mice. Predator and Prey organisms have a certain amount of energy
which depletes over time. Energy is replesnished if the organism feeds, and if the organism's energy reaches 0, they die. 

Organisms may also reproduce once they reach a certain maturity age, and have a certain amount of energy. Reproduction is asexual, meaning that organisms need not
find a mate to reproduce. When an organism reproduces, a new organism of that kind is spawned at their location, and some energy is expended.

## Parameters
* predator_count - the initial number of predatros
* prey_count - the initial number of prey
* initial_food_density - the amount of food that is spawned at the start of the simulation
* food_growth_ticks - the number of ticks needed fo food to grow
* max_arc_turn - the maximum amount (in degrees) that any organism can turn left or right from their current rotation.
* max_prey_step_size - the maximum amount that a prey can move forward. When a prey moves, it moves anywhere from 0 units to this many units. This may be used to model how evasive a prey organism is or how hard it is for predators to catch them
* max_predator_step_size - the maximum amount that a predator can move forward. When a predator moves, it moves anywhere from 0 units to this many units.
* food_saturation - the amount of energy gained by prey from eating food. This may be used to model the average amount of energy gained from feeding on the food.
* prey_saturation - the amount of energy gained by predator from eating prey. This may be used to model the average amoutn of energy gained from feeding on prey.
* prey_reproduction_probability - the probability that a prey will reproduce (assuming they are of mature age and have enough enrgy).
* predator_reproduction_probability - the probability that a predator will reproduce (assuming they are of mature age and have enough energy).
* prey_reproduction_cost - the amount of energy that is expended when prey reproduces (may be interpretted as modeling the average).
* predator_reproduction_cost - the amount of energy that is expended when predator reproduces (may be interpretted as modeling the average).
* prey_maturity_age - the amount of ticks a prey needs to be alive before it is able to reproduce.
* predator_maturity_age - the amount of ticks a predator needs to be alive before it is able to reproduce.

## How to use it?

Open the file in NetLogo and run the model.

## Limitations of the Model
The model is largely realistic based on the trends that were seen in the simulation as compared to what should happen (from the perspective of Differential Equations, for
example). However, there are certain limitations which may be extended upon

1. Asexual Reproduction. Mice and Cats do not reproduce asexually. Mating may be used to add realism to the model. 
2. Consistent Energy from feeding. Currently, when organisms feed in the model, they gain a fixed amount of energy. However, while this may be true "on average", in  reality, 
there is variance in the amount of energy that is obtained when feeding, especially due to the amount of energy that still exists within the organism not counting energy
lost due to heat and imperfect energy transfer.
3. Environmental conditions. In the current model, both predator and prey are free to move to any random patch through any random path. However, in a realistic ecological environment, it is likely that there are obstacles blocking certain paths that organisms can take, or there are paths that they are likelier to utilize for safety and self-preservation reasons. Furthermore, the growth of food and the movement of animals are also affected by other environmental conditions such as climate.
4. Random Motion. As proposed, the predators and prey move randomly within the environment. However, this is generally not the case as organisms are capable of sensing their environment and responding
to threats and stimuli. As such, prey behavior may be extended to avoid predators, and predator behavior may be extended to chase down prey. 
5. Death due to extraneous reasons. The current model has only two possible reasons for an organism to be removed from the environment: (1) consumption by an organism higher up in the food chain, or (2) death due to the lack of energy. To better simulate real-world conditions, death due to other factors can be considered, such as competition among animals of the same species, spontaneous disease, or death due to the environment (e.g. heat stroke, hypothermia, drowning).
