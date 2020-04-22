/***
* Name: Traffic
* Author: alice
* Description: basic traffic model, which is taken as a base for this model

* Tags: Tag1, Tag2, TagN
***/

model Traffic


/* Insert your model definition here */


//QUESTIONS 
// - bloqué dans le percieve, att qd même pour partir mais ducoup n'execute pas le plan work/sleep
global {
	
	//variables environement de transport :
	//map<string, map<string,float>> info_mode_env; //<mode, <critère,valeur>>
	
	//price
	float gas_price;
	float subscription_price;
	
	//safety
	float percentage_of_drivers;
	float number_of_users;
	map<list<int>, int> number_of_users_per_hour;
	//routes & pistes cyclables collées à voir
	
	//ecology
	float air_pollution;
	
	//comfort
	//use of number of users car si c'est bondé c'est moins confortable
	float bus_capacity;//capacity of one bus
	
	
	//time
	float bus_freq; //intervalle en minute
	
	//simplicity
	
	


	list<string> type_mode <- ["car","bus","bike","feet"];
	list<string> criteria <- ["comfort", "safety", "price","ecology","simplicity","time"];
	
	
	//Shapefile of the buildings
	file building_shapefile <- file("../includes/Castanet Tolosan/buildings.shp");
	//Shapefile of the roads
	file road_shapefile <- file("../includes/Castanet Tolosan/roads.shp");
	//Shape of the environment
	geometry shape <- envelope(road_shapefile);
	//Step value
	float step <- 1 #mn;
	//Graph of the road network
	graph road_network;
	
	//date (et heure) de début de la simulation : 7/4/2020 à 6h
	date starting_date <- date(2020,4,7,6);
	

	/*=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-= */ 
	/*										Predicates								 */
	/*=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-= */ 
	
	
	predicate working <- new_predicate("working");
	predicate staying_at_home <- new_predicate("staying_at_home");
	predicate leisure <- new_predicate("leisure");
	predicate eating <- new_predicate("eating");
	predicate at_target <- new_predicate("at target");
//	predicate do_actvity <- new_predicate("do activity");
	
	init {
		
		gas_price <- 1.5; //prix au litre
		subscription_price <- 30.0; //prix par mois
		
		number_of_users <- 0.0;
		percentage_of_drivers <- 0.0;
		
		//Initialization of the building using the shapefile of buildings
		create building from: building_shapefile;
		//Initialization of the road using the shapefile of roads
		create road from: road_shapefile;
		
		//Creation of the people agents
		create people number: 1000 with: [home_building::one_of(building), work_building::one_of(building) ];
      	road_network <- as_edge_graph(road);
      	
//      	loop i from: 0 to: length(type_mode){
//      		info_mode_env[type_mode[i]]["safety"] <- compute_safety(type_mode[i]);
//      		info_mode_env[type_mode[i]]["time"] <- compute_time(type_mode[i]);
//      		info_mode_env[type_mode[i]]["ecology"] <- compute_ecology(type_mode[i]);
//      		info_mode_env[type_mode[i]]["comfort"] <- compute_comfort(type_mode[i]);
//      		info_mode_env[type_mode[i]]["price"] <- compute_price(type_mode[i]);
//      		info_mode_env[type_mode[i]]["simplicity"] <- compute_simplicity(type_mode[i]);
//	  	}
      	
      	
	}	
	
	
	//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==-=-=-=--=-=-=-=-=-=-=-=-=-=-=-=
	// FONCTIONS MAJ ENV
	//=-=-=-=-=-=-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-==-=-=-=-=-=-=-=-=-=-=
	
//
//	
//	float compute_safety(string type){
//		float val; // Val doit avoir une valeur entre 0 et 1
//		switch type {
//			match "car" {
//				// fréquentation des routes, à voir comment définir // nb of visitors
//			}
//			match "bike" {
//				//taux de route collées aux pistes cyclables. à voir comment avoir cette info
//			}
//			match "bus" {
//				//frequentation des TeC, car plus grand risque d'agression. 
//			}
//			match "feet"{
//				//selon genre/heure de la journée donc à voir selon l'agent
//			}
//		}	
//		return val;
//	}
//	
//	
//	float compute_time(string type){ //maybe pas pertinant dans l'environnement car est vraiment situationnel de la position de l'agent et de sa cible
//		float val; // Val doit avoir une valeur entre 0 et 1
//		switch type {
//			match "car" {
//				// temps moyen à moyenner par agent ?
//			}
//			match "bike" {
//				//distance + "croisements" avec d'autres routes (cf article le monde diplo)
//			}
//			match "bus" {
//				//distance +freq
//			}
//			match "feet"{
//				//distance
//			}
//		}	
//		return val;
//	}
//	
//	
//	float compute_comfort(string type){
//		float val; // Val doit avoir une valeur entre 0 et 1
//		switch type {
//			match "car" {
//				val <- 1.0;
//			}
//			match "bike" {
//				//selon le niveau de sportivité de l'agent + distance
//			}
//			match "bus" {
//				//taux de personnes empruntant les TeC, car moins de place 
//			}
//			match "feet"{
//				//selon la distance
//			}
//		}	
//		return val;
//	}
//	
//	
//	float compute_price(string type){
//		float val; // Val doit avoir une valeur entre 0 et 1
//		switch type {
//			match "car" {
//				// selon essence + trajet
//			}
//			match "bike" {
//				val <- 1.0;
//			}
//			match "bus" {
//				//prix abonnement
//			}
//			match "feet"{
//				val <- 1.0;
//			}
//		}	
//		return val;
//	}
//	
//	//SELON AGENT
//	float compute_ecology(string type){
//		float val; // Val doit avoir une valeur entre 0 et 1
//		switch type {
//			match "car" {
//				// selon la distance + pollution générale
//			}
//			match "bike" {
//				val <- 1.0;
//			}
//			match "bus" {
//				//à moitié ecolo + pollutuon générale
//			}
//			match "feet"{
//				val <- 1.0;
//			}
//		}	
//		return val;
//	}
//	
//	
//	float compute_simplicity(string type){ //SELON AGENT
//		float val; // Val doit avoir une valeur entre 0 et 1
//		switch type {
//			match "car" {
//				// selon parking
//			}
//			match "bike" {
//				//selon les infrastructures de pistes cyclables (rejoins un peu danger)
//			}
//			match "bus" {
//				//changements nécéssaires pour arriver a destination
//			}
//			match "feet"{
//				//selon distance
//			}
//		}	
//		return val;		
//	}
	
	
}//fin global
	
	


//Species to represent the people using the skill moving
species people skills: [moving] control:simple_bdi{
	list<map<list<int>, predicate>> agenda_week;
	point target;
	building target_building;
	
	//addresses of agent
	building work_building;
	building home_building;
	
	rgb color <-#red;
	
	map<string,int> grades;
	
	map<string, map<string,float>> info_mode_user;
	
	float distance;
	
	init{
		//People agents are located anywhere in one of the building
		location <- home_building.location;
		
		distance <- home_building distance_to work_building;
		
		loop i from: 0 to: length(criteria){
      		grades[criteria[i]]<- rnd(9);
	  	}
		
		
		//0 = lundi; 6 = dimanche
		loop i from: 0 to: 6 {
			// ce que je fais durant la journee
			
			map<list<int>,predicate> agenda_day;
			if (i < 5) {
				agenda_day[[8,30]] <- working;
				agenda_day[[12,0]] <- eating;
				agenda_day[[13,30]] <- working; 
				agenda_day[[17,30]] <- staying_at_home; 
			} else {
				agenda_day[[12,0]] <- eating;
				agenda_day[[15,0]] <- leisure;
			}
			agenda_week << agenda_day;
		}
		do add_desire(staying_at_home);
		
	}
	
	
	//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
	// Maj var agent
	//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
	float compute_value(string type, string criterion){ //compute contextual value according to mode and criteria
		float val;
		switch type {
			match "car" {
				switch criterion {
					match "comfort" {
						val <- 1.0;
					}
					match "price" {
						//on considère qu'une voiture dépense 7,2 litres pour 100 km(moyenne sur 2019)
						float abs_price <- 7.2*distance/100*gas_price;
						//voir comment normaliser
					}
					match "time" {
						//on considère que la voiture à une allure moyenne de 25km/h
						float abs_time <- distance/25.0;
						//pareil, normaliser en comparant avec les autres ?
					}
					match "ecology"{
						val <-0.0;
					}
					match "simplicity"{
						val <- 1.0;
					}
					match "safety"{
						val <- percentage_of_drivers/100;
						//eventuellement prendre en compte la capacité de la route ? est-ce une info à la quelle on a accès ?
					}
				}	
			}//end match car
			match "bike" {
				switch criterion {
					match "comfort" {
						//enfants, motif du déplacement
					}
					match "price" {
						val <- 1.0;
					}
					match "time" {
						//on considère que les vélos se déplacent en moyenne à 10km/h
						float abs_time <- distance/10.0;
					}
					match "ecology"{
						val <- 1.0;
					}
					match "simplicity"{
						// dans le trajet effectué, voir pourcentage route cyclables + distance au dessus de 20min pas cool (voir papiers socio)
					}
					match "safety"{
						//dans le trajet effectué pourcentage de route non partagée avec automobilistes
					}			
				}
			}//end match bike
			match "bus" {
				switch criterion {
					match "comfort" {
						//selon son heure de départ
						//nb de personnes qu'on peut transporter en 30min - nb actuel de passager
						float val1 <- ((30/bus_freq)* bus_capacity) - number_of_users_per_hour[[current_date.hour,floor(current_date.minute/30)*30]];
						val <- val1/((30/bus_freq)* bus_capacity);
					}
					match "price" {
					 float abs_price <- subscription_price;
					}
					match "time" {
						// On considère qu'un bus se déplace à 10km/h
						float abs_time <- distance/10.0;
					}
					match "ecology"{
						val <- 0.75;
					}
					match "simplicity"{
						//Dépend du nombre de ligne de bus différentes à prendre; à voir comment faire avec ces data
					}
					match "safety"{
						if(current_date.hour>21.0){
							val <- 0.5;
						} else {
							val <- 0.90;
						}
					}
				}
				
			}//end match bus
			match "feet"{
				switch criterion {
					match "comfort" {
						if(distance < 3){
							val <- 1- distance /3.0;
						} else {
							val <- 0.0;
						}
					}
					match "price" {
						val <- 1.0;
					}
					match "time" {
						float abs_time <- distance/5;
					}
					match "ecology"{
						val <- 1.0;
					}
					match "simplicity"{
						if(distance < 3){
							val <- 1- distance /3.0;
						} else {
							val <- 0.0;
						}
					}
					match "safety"{
						if(current_date.hour > 21 or current_date.hour<5){
							val <- 0.2;
						} else {
							val <- 1.0;
						}
					}			
					
				}//end match criterion
			}//end match feet
		}//end switch
		
		return val;
	}

	
	float compute_priority_mobility_mode(string type) {
		float val <- 0.0;
		loop i from: 0 to: length(criteria){
			val <- grades[criteria[i]]*compute_value(type,criteria[i]);
		}
	
		return val/length(criteria);
	}
	
	
	
	bool is_time(int hour, int minute) {
		return current_date.hour = hour and current_date.minute = minute;
	}
	
	reflex executeAgenda {
		predicate act <- agenda_week[current_date.day_of_week - 1][[current_date.hour,current_date.minute]];
		if (act != nil) {
			if (get_current_intention() != nil) {
				do remove_intention(first(intention_base).predicate, true);
			}
			
			do remove_belief(at_target);
			do add_desire(act);
		}
	}
	
	plan do_work intention: working{
		if (not has_belief(at_target)) {
			target <- any_location_in(work_building);
			do add_subintention(get_current_intention(),at_target, true);
			do current_intention_on_hold();
		}
		color <- #blue;
	}
	
	
	plan do_stay_at_home intention: staying_at_home{
		if (not has_belief(at_target)) {
			target <- any_location_in(home_building);
			do add_subintention(get_current_intention(),at_target, true);
			do current_intention_on_hold();
		}
		color <- #red;
	}
	
	plan do_eating_at_home intention: eating priority: rnd(1.0){
		if (not has_belief(at_target)) {
			target <- any_location_in(home_building);
			do add_subintention(get_current_intention(),at_target, true);
			do current_intention_on_hold();
		}
		color <- #yellow;
	}
	
	plan do_eating_restaurant intention: eating priority: rnd(1.0){
		if (not has_belief(at_target)) {
			target <- any_location_in(one_of(building));
			do add_subintention(get_current_intention(),at_target, true);
			do current_intention_on_hold();
		}
		color <- #green;
	}
	
	plan see_a_movie intention: leisure priority: rnd(1.0){
		if (not has_belief(at_target)) {
			target <- any_location_in(one_of(building));
			do add_subintention(get_current_intention(),at_target, true);
			do current_intention_on_hold();
		}
		color <- #magenta;
	}
	
	plan meet_a_friend intention: leisure priority: rnd(1.0){
		if (not has_belief(at_target)) {
			target <- any_location_in(one_of(building));
			do add_subintention(get_current_intention(),at_target, true);
			do current_intention_on_hold();
		}
		color <- #blue;
	}
	
	
	
	
		
	//normal move plan
	plan driving intention: at_target  finished_when: target = location priority: compute_priority_mobility_mode("car"){
		do goto target: target on: road_network speed: 20 #km/#h return_path: true;
		if (target = location) {
			do add_belief(at_target);
		}
	}
	
	plan cycling intention: at_target  finished_when: target = location priority: compute_priority_mobility_mode("bike"){
		do goto target: target on: road_network speed: 10 #km/#h;
		if (target = location) {
			do add_belief(at_target);
		}
	}
	
	plan walking intention: at_target  finished_when: target = location priority: compute_priority_mobility_mode("feet"){
		do goto target: target on: road_network speed: 5 #km/#h;
		if (target = location) {
			do add_belief(at_target);
		}
	}
	
	plan taking_bus intention: at_target  finished_when: target = location priority: compute_priority_mobility_mode("bus"){
		do goto target: target on: road_network speed: 10 #km/#h;
		if (target = location) {
			do add_belief(at_target);
		}
	}
	
	aspect default {
		draw circle(20) color: color border: #black depth: 1.0;
	}	
		
}
	
	
	


//Species to represent the buildings
species building {
	string type;
	aspect default {
		draw shape color: #gray border: #black;
	}
}


//Species to represent the roads
species road {
	aspect default {
		draw shape color: #red;
	} 
}

experiment traffic type: gui {
	output {
		display map type: opengl draw_env: false{
			image "../includes/Castanet Tolosan/satellite.png"  transparency: 0.1 refresh: false;
			species building;
			species road;
			species people;
			
		}
	}
}
