/**
* Name: preypredator
* Based on the internal skeleton template. 
* Author: mathias
* Tags: 
*/

model preypredator

global torus:true {
	/** Insert the global definitions, variables and actions here */
	int nb_preys <- 200;
	int nb_predators <- 50;
	float sum_vegetation_energy <- 0.0;
	
	float prey_max_energy <- 1.0;
	float prey_max_transfert <- 0.1;
	float prey_energy_consumption <- 0.05;
	
	float prey_probability_reproduction <- 0.01;
	int prey_nb_max_offsprings <- 5;
	float prey_energy_reproduce <- 0.5;
	float prey_prop_male_female <- 0.50;

	int prey_max_life <- rnd(200#cycle, 300#cycle);
	int prey_maturity <- int(0.25 * prey_max_life);
	int prey_max_wait_repro <- int(0.1 * prey_max_life);
	
	float predator_max_energy <- 1.0;
	float predator_max_transfert <- 0.5;
	float predator_energy_consumption <- 0.005;
	
	float predator_probability_reproduction <- 0.01;
	int predator_nb_max_offsprings <- 3;
	float predator_energy_reproduce <- 0.5;
	float predator_prop_male_female <- 0.33;

	int predator_max_life <- rnd(200#cycle, 400#cycle);
	int predator_maturity <- int(0.33 * predator_max_life);
	int predator_max_wait_repro <- int(0.1 * predator_max_life);
	
	init {
		create prey number: nb_preys;
		create predator number: nb_predators;

		sum_vegetation_energy <- 0.0;
		loop cell over: vegetation {
			sum_vegetation_energy <- sum_vegetation_energy + cell._energy;
		}
	}

	int cycles <- 2#cycle;
}

grid vegetation width: 50 height: 50 neighbors: 6 {
	float _max_energy <- 1.0;
	float _prod_energy <- rnd(0.01);
	float _energy <- rnd(_max_energy) update: _energy + _prod_energy max: _max_energy;
	rgb color <- rgb(int(255 * (1 - _energy)), 255, int(255 * (1 - _energy))) update: rgb(int(255 * (1 - _energy)), 255, int(255 * (1 - _energy)));

	list<vegetation> _vNeighbors <- self neighbors_at 1;
}

species animal {
	float _size <- 0.52;
	rgb _color;
	
	float _max_energy;
	float _max_transfert;
	float _energy_consumption;

	bool _is_female;
	float _probability_reproduction;
	int _nb_max_offsprings;
	float _energy_reproduce;
	float _gender_proportion;
	list<animal> _same_cell_animals;

	int _maturity;
	int _max_life;
	int _life <- 0#cycle update: _life + 1#cycle max: _max_life;
	int _wait_repro <- 0#cycle update: _wait_repro - 1#cycle min: 0;
	int _max_wait_repro;
	
	vegetation _cellule <- one_of(vegetation);
	
	aspect base {
		draw circle(_size) color: _color;
	}
	
	init {
		location <- _cellule.location;
	}

	float _energy <- _max_energy update: (_energy - _energy_consumption) max: _max_energy;
	
	reflex eat {
		write "J'ai faim...";
	}

	reflex reproduction when: /*flip(_probability_reproduction)*/ self._is_female = true and self._wait_repro = 0 and self._life >= self._maturity and one_matches(species(self) inside self._cellule, each._is_female = false and each._life >= each._maturity) {
		create species(self) number: rnd(_nb_max_offsprings) {
			self._cellule <- myself._cellule;
			self.location <- myself._cellule.location;
			self._energy <- myself._energy / 4;
			myself._energy <- myself._energy / 4;
		}

		_wait_repro <- _max_wait_repro;
	}

	reflex die when: _energy <= 0.0 or _life = _max_life {
		do die;
	}

	action chooseGender {
		float n <- 100.0;
		
		_is_female <- (rnd(n) / n < _gender_proportion)?false:true;
	}
}
	
species prey parent: animal {
	init {
		_color <- #blue;
		
		_max_energy <- prey_max_energy;
		_max_transfert <- prey_max_transfert;
		_energy_consumption <- prey_energy_consumption;
		
		_probability_reproduction <- prey_probability_reproduction;
		_nb_max_offsprings <- prey_nb_max_offsprings;
		_energy_reproduce <- prey_energy_reproduce;
		_gender_proportion <- prey_prop_male_female;

		_energy <- _max_energy;

		do chooseGender;

		_maturity <- prey_maturity;
		_max_life <- prey_max_life;
		_max_wait_repro <- prey_max_wait_repro;
	}

	reflex move /*when: _cellule._energy <= 0.0 or _energy >= 0.9*_max_energy*/ {
		if(_energy > 0.8*_max_energy and _life >= _maturity and _wait_repro = 0){
			loop cell over: _cellule._vNeighbors {
				if(one_matches(prey inside cell, each._is_female = !self._is_female and each._life >= each._maturity)){
					_cellule <- cell;
					break;
				}
			}
		} else {
			float max <- _cellule._vNeighbors max_of(each._energy);
			
			loop cell over: _cellule._vNeighbors {
				if(cell._energy = max){
					_cellule <- cell;
					break;
				}
			}
		}
		
		location <- _cellule.location;
	}

	reflex eat when: _cellule._energy > 0.0 and _energy < _max_energy {
		if(_cellule._energy > _max_transfert){
			_cellule._energy <- _cellule._energy - _max_transfert;
			_energy <- _energy + _max_transfert;
		} else if(_energy + _max_transfert > _max_energy){
			_cellule._energy <- _cellule._energy - (_max_energy - _energy);
			_energy <- _max_energy;
		} else {
			_energy <- _energy + _cellule._energy;
			_cellule._energy <- 0.0;
		}
	}
}
	
species predator parent: animal {
	init {
		_color <- #red;
		
		_max_energy <- predator_max_energy;
		_max_transfert <- predator_max_transfert;
		_energy_consumption <- predator_energy_consumption;
		
		_probability_reproduction <- predator_probability_reproduction;
		_nb_max_offsprings <- predator_nb_max_offsprings;
		_energy_reproduce <- predator_energy_reproduce;
		_gender_proportion <- predator_prop_male_female;
		
		_energy <- _max_energy;

		do chooseGender;

		_maturity <- predator_maturity;
		_max_life <- predator_max_life;
		_max_wait_repro <- predator_max_wait_repro;
	}

	reflex move_predator {
		_same_cell_animals <- prey inside _cellule;
	}

	reflex move {
		if(_energy > 0.8*_max_energy and _life >= _maturity and _wait_repro = 0){
			loop cell over: _cellule._vNeighbors {
				if(one_matches(predator inside cell, each._is_female = !self._is_female and each._life >= each._maturity)){
					_cellule <- cell;

					break;
				}
			}
		} else {
			bool found <- false;

			loop cell over: _cellule._vNeighbors {
				list<prey> nearest <- prey inside cell;

				if(!empty(nearest)){
					found <- true;
					_cellule <- cell;
					break;
				}
			}

			if(!found){
				_cellule <- one_of(_cellule._vNeighbors);
			}
		}
		
		location <- _cellule.location;
	}

	reflex eat when: !empty(_same_cell_animals) {
		prey obj <- one_of(list<prey>(_same_cell_animals));

		_energy <- (_energy + obj._energy >= _max_energy) ? _max_energy : _energy + obj._energy;

		ask obj {
			do die;
		}
	}
}

experiment prey_predator type: gui {
	/** Insert here the definition of the input and output of the model */
	parameter "Initial number of preys: " var: nb_preys min: 0 max: 1000 category: "Preys" ;
	parameter "Initial number of predators: " var: nb_predators min: 0 max: 200 category: "Predators" ;
	
	parameter "Prey max energy: " var: prey_max_energy category: "Preys" ;
	parameter "Prey max transfert: " var: prey_max_transfert category: "Preys" ;
	parameter "Prey energy consumption: " var: prey_energy_consumption category: "Preys" ;
	parameter "Prey probability reproduce: " var: prey_probability_reproduction category: "Preys" ;
	parameter "Prey nb max offsprings: " var: prey_nb_max_offsprings category: "Preys" ;
	parameter "Prey energy reproduce: " var: prey_energy_reproduce category: "Preys" ;
	
	parameter "Predator max _energy: " var: predator_max_energy category: "Predators" ;
	parameter "Predator max transfert: " var: predator_max_transfert category: "Predators" ;
	parameter "Predator energy consumption: " var: predator_energy_consumption category: "Predators" ;
	parameter "Predator probability reproduce: " var: predator_probability_reproduction category: "Predators" ;
	parameter "Predator nb max offsprings: " var: predator_nb_max_offsprings category: "Predators" ;
	parameter "Predator energy reproduce: " var: predator_energy_reproduce category: "Predators" ;
	
	reflex refresh_values when: every(cycles) {
 		nb_predators <- length(predator);
		nb_preys <- length(prey);

		sum_vegetation_energy <- 0.0;
		loop cell over: vegetation {
			sum_vegetation_energy <- sum_vegetation_energy + cell._energy;
		}
	}

	output {
		display main_display {
			grid vegetation;
			species prey aspect: base;
			species predator aspect: base;
		}

		monitor "Number of predators: " value: nb_predators;
		monitor "Number of preys: " value: nb_preys;
		monitor "Sum of the vegetation: " value: sum_vegetation_energy;
		
		display Population_information refresh:every(cycles) {
			chart "evolution des individus" type: series size: {0.5,0.5} position: {0, 0}
			{
				data "number_of_preys" value: nb_preys color: #blue ;
			}
			chart "evolution des individus" type: series size: {0.5,0.5} position: {0.5, 0}
			{
				data "number_of_predators" value: nb_predators color: #red ;
			}
			chart "evolution de la végétation" type: series size: {0.5,0.5} position: {0, 0.5}
			{
				data "sum_vegetation_energy" value: sum_vegetation_energy color: #green ;
			}
		}
	}
}
