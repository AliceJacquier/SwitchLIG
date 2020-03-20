/***
* Name: Traffic
* Author: alice
* Description: basic traffic model, which is taken as a base for this model

* Tags: Tag1, Tag2, TagN
***/

model Traffic

/* Insert your model definition here */


global {
	//Shapefile of the buildings
	file building_shapefile <- file("../includes/buildings2.shp");
	//Shapefile of the roads
	file road_shapefile <- file("../includes/roads.shp");
	//Shape of the environment
	geometry shape <- envelope(road_shapefile);
	//Step value
	float step <- 10 #s;
	//Graph of the road network
	graph road_network;
	//Map containing all the weights for the road network graph
	map<road,float> road_weights;
	

	
	//go by *any mean* predicates are supposed to be desires or intent ? 
	
	
	init {
		//Initialization of the building using the shapefile of buildings
		create building from: building_shapefile;
		//Initialization of the road using the shapefile of roads
		create road from: road_shapefile;
		
		//Creation of the people agents
		create people number: 100{
			//People agents are located anywhere in one of the building
			location <- any_location_in(one_of(building));
      	}
      	//Weights of the road
      	road_weights <- road as_map (each::each.shape.perimeter);
      	road_network <- as_edge_graph(road);
	}
	//Reflex to update the speed of the roads according to the weights
	reflex update_road_speed  {
		road_weights <- road as_map (each::each.shape.perimeter / each.speed_coeff);
		road_network <- road_network with_weights road_weights;
	}
	
	//Reflex to decrease and diffuse the pollution of the environment
	reflex pollution_evolution{
		//ask all cells to decrease their level of pollution
		ask cell {pollution <- pollution * 0.7;}
		
		//diffuse the pollutions to neighbor cells
		diffuse var: pollution on: cell proportion: 0.9 ;
	}
}

//Species to represent the people using the skill moving
species people skills: [moving] control:simple_bdi{
	
	//addresses of agent
	point addr_home ;
	point addr_work;
	building work_building;
	
	float beginning_time;
	float ending_time;
	
	path path_home_work;
	path path_work_home;
	
	float view_dist <- 10.0;
	
	//Speed of the agent
	float speed <- 5 #km/#h;
	
	rgb color <- rnd_color(255);
	
	list<int> bus_grades;
	list<int> car_grades;
	list<int> bike_grades;
	list<int> weights_grades;
	
	init{
		
		beginning_time<-8.50; //todo : init with a random value with stats bc of night shift for instance
		
		addr_home <- any_location_in(one_of(building)); //Rajouter un where pour le type
		addr_work <- any_location_in(one_of(building));
		//How agents grade differents criteria about each transport mode, from 0 to 10.
		bus_grades <- [4,7,8,4];//confort, time, price (9 = cheap), simplicity (0= complex)
		car_grades <- [9,4,3,8];
		bike_grades <- [3,9,9,9];
		weights_grades <-[8,5,8,7]; 
		
		do add_desire(go_to_work);
	}
	
	
	
	/*=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-= */ 
	/*										Predicates								 */
	/*=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-= */ 
	predicate go_to_work <- new_predicate("go to work");
	predicate go_home <- new_predicate("go home");
	predicate go_by_bike <- new_predicate("go by bike");
	predicate go_by_car <- new_predicate("go by car");
	predicate go_by_bus <- new_predicate("go by bus");
	predicate bus_is_best <- new_predicate("bus is best");
	predicate bike_is_best <- new_predicate("bike is best");
	predicate car_is_best <- new_predicate("car is best");
	//desirs avec priorité sur les paramètres
	
	
	/*=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-= */ 
	/*										Percieve									 */
	/*=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-= */
	
	//We arrived work
	//à quoi ça sert de mettre perceive building ici ? ça marche pas sans le percieve anyway mais bon.
	perceive target: building where(location distance_to addr_work < 2) in: view_dist {
		ask myself {
			do remove_intention(go_to_work, true);	
			do add_desire(go_home);			
		}
	}
	
		
	//We arrived home
	perceive target: building where(location distance_to addr_home < 2) in: view_dist {
		ask myself {
			do remove_intention(go_home, true);	
			do add_desire(go_to_work);			
		}
	}
	
	
	/*=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-= */ 
	/*										Plans									 */
	/*=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-= */
	
	plan lets_go_to_work intention: go_to_work {
		path path_followed <- goto (target: addr_work, on: road_network, recompute_path: false, return_path: true, move_weights: road_weights);
		
		if (path_followed != nil ) {
			ask (cell overlapping path_followed.shape) {
				pollution <- pollution + 10.0;
			} 
		}
	}
	
	
	plan lets_go_home intention: go_home{
		path path_followed <- goto (target: addr_home, on: road_network, recompute_path: false, return_path: true, move_weights: road_weights);
		
		if (path_followed != nil ) {
			ask (cell overlapping path_followed.shape) {
				pollution <- pollution + 10.0;
			} 
		}
	}
		
		
	
	
	/*=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-= */ 
	/*										Actions									 */
	/*=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-= */
	
	//TODO : add the psychology biases that i've been reading
	action evaluate_transport{
		float mean_bus;
		float mean_car;
		float mean_bike;
		
		mean_bus <- (weights_grades[0]*bus_grades[0] + weights_grades[1]*bus_grades[1] + weights_grades[2]*bus_grades[2]+ weights_grades[3]*bus_grades[3])/4;
		mean_car <- (weights_grades[0]*car_grades[0] + weights_grades[1]*car_grades[1] + weights_grades[2]*car_grades[2]+ weights_grades[3]*car_grades[3])/4;
		mean_bike <- (weights_grades[0]*bike_grades[0] + weights_grades[1]*bike_grades[1] + weights_grades[2]*bike_grades[2]+ weights_grades[3]*bike_grades[3])/4;
		
		
		
		do remove_belief(car_is_best);
		do remove_belief(bus_is_best);
		do remove_belief(bike_is_best);
			
		if (mean_bus > mean_car){
			if(mean_bus > mean_bike){
				do add_belief(bus_is_best);
			} else {
				do add_belief(bike_is_best);
			}
		} else if (mean_car > mean_bike){
			do add_belief(car_is_best);
		} else {
			do add_belief(bike_is_best);
		}
		
	}
		
		
		
		aspect default {
			draw circle(20) color: color;
		}	
		
	}
	
	



//Species to represent the means of transportation.

species transport {
	
	
}


//Species to represent the buildings
species building {
	string type;
	aspect default {
		draw shape color: #gray;
	}
}





//Species to represent the roads
species road {
	//Capacity of the road considering its perimeter
	float capacity <- 1 + shape.perimeter/30;
	//Number of people on the road
	int nb_people <- 0 update: length(people at_distance 1);
	//Speed coefficient computed using the number of people on the road and the capicity of the road
	float speed_coeff <- 1.0 update:  exp(-nb_people/capacity) min: 0.1;
	int buffer<-3;
	aspect default {
		draw (shape + buffer * speed_coeff) color: #red;
	} 
}

//cell use to compute the pollution in the environment
grid cell height: 50 width: 50 neighbors: 8{
	//pollution level
	float pollution <- 0.0 min: 0.0 max: 100.0;
	
	//color updated according to the pollution level (from red - very polluted to green - no pollution)
	rgb color <- #green update: rgb(255 *(pollution/30.0) , 255 * (1 - (pollution/30.0)), 0.0);
}

experiment traffic type: gui {
	float minimum_cycle_duration <- 1.0;
	output {
		display carte type: opengl{
			species building refresh: false;
			species road ;
			species people ;
			
			//display the pollution grid in 3D using triangulation.
			grid cell elevation: pollution * 3.0 triangulation: true transparency: 0.7;
		
		}
	}
}
