/***
* Part of the GAMA CoVid19 Modeling Kit
* see http://gama-platform.org/covid19
* Author: Patrick Taillandier
* Tags: covid19,epidemiology, gis
***/

model CoVid19

global {
	
	//define the path to the dataset folder
	string dataset_path <- "../includes/Castanet Tolosan";
	
	
	//define the bounds of the studied area
	file data_file <-shape_file(dataset_path + "/boundary.shp");
	
	
	//optional
	string osm_file_path <- dataset_path + "/map.osm";
		
	float mean_area_flats <- 200.0;
	float min_area_buildings <- 20.0;
	
	bool display_google_map <- true parameter:"Display google map image";
	
	//-----------------------------------------------------------------------------------------------------------------------------
	
	list<rgb> color_bds <- [rgb(241,243,244), rgb(255,250,241)];
	
	map<string,rgb> google_map_type <- ["restaurant"::rgb(255,159,104), "shop"::rgb(73,149,244)];
	
	geometry shape <- envelope(data_file);
	map filtering <- ["building"::[], "shop"::[], "historic"::[], "amenity"::[], "sport"::[], "military"::[], "leisure"::[], "office"::[],  "highway"::[]];
	image_file static_map_request ;
	init {
		write "Start the pre-processing process";
		create Boundary from: data_file;
		
		osm_file osmfile;
		if (file_exists(osm_file_path)) {
			osmfile  <- osm_file(osm_file_path, filtering);
		} else {
			point top_left <- CRS_transform({0,0}, "EPSG:4326").location;
			point bottom_right <- CRS_transform({shape.width, shape.height}, "EPSG:4326").location;
			string adress <-"http://overpass.openstreetmap.ru/cgi/xapi_meta?*[bbox="+top_left.x+"," + bottom_right.y + ","+ bottom_right.x + "," + top_left.y+"]";
			osmfile <- osm_file<geometry> (adress, filtering);
		}
		
		write "OSM data retrieved";
		list<geometry> geom <- osmfile  where (each != nil and not empty(Boundary overlapping each) );
		
		create Building from: geom with:[building_att:: get("building"),shop_att::get("shop"), historic_att::get("historic"), 
			office_att::get("office"), military_att::get("military"),sport_att::get("sport"),leisure_att::get("lesure"),
			height::float(get("height")), flats::int(get("building:flats")), levels::int(get("building:levels"))
		];
		ask Building {
			if (shape = nil) {do die;} 
		}
		list<Building> bds <- Building where (each.shape.area > 0);
		ask Building where ((each.shape.area = 0) and (each.shape.perimeter = 0)) {
			list<Building> bd <- bds overlapping self;
			ask bd {
				sport_att  <- myself.sport_att;
				office_att  <- myself.office_att;
				military_att  <- myself.military_att;
				leisure_att  <- myself.leisure_att;
				amenity_att  <- myself.amenity_att;
				shop_att  <- myself.shop_att;
				historic_att <- myself.historic_att;
			}
			do die; 
		}
		ask Building where (each.shape.area < min_area_buildings) {
			do die;
		}
		ask Building {
			if (amenity_att != nil) {
				type <- amenity_att;
			}else if (shop_att != nil) {
				type <- shop_att;
			}
			else if (office_att != nil) {
				type <- office_att;
			}
			else if (leisure_att != nil) {
				type <- leisure_att;
			}
			else if (sport_att != nil) {
				type <- sport_att;
			} else if (military_att != nil) {
				type <- military_att;
			} else if (historic_att != nil) {
				type <- historic_att;
			} else {
				type <- building_att;
			} 
		}
		
		ask Building where (each.type = nil or each.type = "") {
			do die;
		}
		ask Building {
			if (flats = 0) {
				if type in ["apartments","hotel"] {
					if (levels = 0) {levels <- 1;}
					flats <- int(shape.area / mean_area_flats) * levels;
				} else {
					flats <- 1;
				}
			}
		}
	
		
		save Building to:dataset_path +"/buildings.shp" type: shp attributes: ["type"::type, "flats"::flats,"height"::height, "levels"::levels];
		
		
		map<string, list<Building>> buildings <- Building group_by (each.type);
		loop ll over: buildings {
			rgb col <- rnd_color(255);
			ask ll {
				color <- col;
			}
		}
		
		list<geometry> geom_road <- osmfile  where (each != nil and not empty(Boundary overlapping each));
		loop geom over: geom_road {
			string highway_str <- string(geom get ("highway"));
				if (length(geom.points) > 1 ) {
					string oneway <- string(geom get ("oneway"));
					float maxspeed_val <- float(geom get ("maxspeed"));
					string lanes_str <- string(geom get ("lanes"));
					int lanes_val <- empty(lanes_str) ? 1 : ((length(lanes_str) > 1) ? int(first(lanes_str)) : int(lanes_str));
					create Road with: [shape ::geom, type:: highway_str, oneway::oneway, maxspeed::maxspeed_val, lanes::lanes_val] {
						if lanes < 1 {lanes <- 1;} //default value for the lanes attribute
						if maxspeed = 0 {maxspeed <- 50.0;} //default value for the maxspeed attribute
					}
				}
		}
		
		graph network<- main_connected_component(as_edge_graph(Road));
		ask Road {
			if not (self in network.edges) {
				do die;
			}
		}
		save Road type:"shp" to:dataset_path +"/roads.shp" attributes:["lanes"::self.lanes, "maxspeed"::maxspeed, "oneway"::oneway] ;
		do load_satellite_image;
	}
	
	
	
	action load_satellite_image
	{ 
		point top_left <- CRS_transform({0,0}, "EPSG:4326").location;
		point bottom_right <- CRS_transform({shape.width, shape.height}, "EPSG:4326").location;
		int size_x <- 1500;
		int size_y <- 1500;
		
		string rest_link<- "https://dev.virtualearth.net/REST/v1/Imagery/Map/Aerial/?mapArea="+bottom_right.y+"," + top_left.x + ","+ top_left.y + "," + bottom_right.x + "&mapSize="+int(size_x)+","+int(size_y)+ "&key=AvZ5t7w-HChgI2LOFoy_UF4cf77ypi2ctGYxCgWOLGFwMGIGrsiDpCDCjliUliln" ;
		static_map_request <- image_file(rest_link);
	
		write "Satellite image retrieved";
		ask cell {		
			color <-rgb( (static_map_request) at {grid_x,1500 - (grid_y + 1) }) ;
		}
		save cell to: dataset_path +"/satellite.png" type: image;
		
		string rest_link2<- "https://dev.virtualearth.net/REST/v1/Imagery/Map/Aerial/?mapArea="+bottom_right.y+"," + top_left.x + ","+ top_left.y + "," + bottom_right.x + "&mmd=1&mapSize="+int(size_x)+","+int(size_y)+ "&key=AvZ5t7w-HChgI2LOFoy_UF4cf77ypi2ctGYxCgWOLGFwMGIGrsiDpCDCjliUliln" ;
		file f <- json_file(rest_link2);
		list<string> v <- string(f.contents) split_with ",";
		int ind <- 0;
		loop i from: 0 to: length(v) - 1 {
			if ("bbox" in v[i]) {
				ind <- i;
				break;
			}
		} 
		float long_min <- float(v[ind] replace ("'bbox'::[",""));
		float long_max <- float(v[ind+2] replace (" ",""));
		float lat_min <- float(v[ind + 1] replace (" ",""));
		float lat_max <- float(v[ind +3] replace ("]",""));
		point pt1 <- to_GAMA_CRS({lat_min,long_max}, "EPSG:4326").location ;
		point pt2 <- to_GAMA_CRS({lat_max,long_min},"EPSG:4326").location;
		pt1 <- CRS_transform(pt1, "EPSG:3857").location ;
		pt2 <- CRS_transform(pt2,"EPSG:3857").location;
		float width <- abs(pt1.x - pt2.x)/1500;
		float height <- abs(pt1.y - pt2.y)/1500;
		
		string info <- ""  + width +"\n0.0\n0.0\n"+height+"\n"+min(pt1.x,pt2.x)+"\n"+min(pt1.y,pt2.y);
		save info to: dataset_path +"/satellite.pgw";
		
		
		write "Satellite image saved with the right meta-data";
		 
		
	}
	
	
}


species Road{
	rgb color <- #red;
	string type;
	string oneway;
	float maxspeed;
	int lanes;
	aspect base_ligne {
		draw shape color: color; 
	}
	
} 
grid cell width: 1500 height:1500 use_individual_shapes: false use_regular_agents: false use_neighbors_cache: false;

species Building {
	string type;
	string building_att;
	string shop_att;
	string historic_att;
	string amenity_att;
	string office_att;
	string military_att;
	string sport_att;
	string leisure_att;
	float height;
	int flats;
	int levels;
	rgb color;
	aspect default {
		draw shape color: color border: #black depth: (1 + flats) * 3;
	}
}

species Boundary {
	aspect default {
		draw shape color: #gray border: #black;
	}
}

experiment generateGISdata type: gui {
	output {
		display map type: opengl draw_env: false{
			image dataset_path +"/satellite.png"  transparency: 0.2 refresh: false;
			species Building;
			species Road;
		}
	}
}
