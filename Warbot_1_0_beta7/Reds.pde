///////////////////////////////////////////////////////////////////////////
//
// The code for the green team
// ===========================
//
final int TARGET_DESTROYED = 6;

///////////////////////////////////////////////////////////////////////////

class RedTeam extends Team {
  final int MY_CUSTOM_MSG = 5;
  final int TARGET_DESTROYED = 6;//message qui informe si la target à l'emplacement X Y a été détruite
}

///////////////////////////////////////////////////////////////////////////
//
// The code for the green bases
//
///////////////////////////////////////////////////////////////////////////
class RedBase extends Base {
  //
  // constructor
  // ===========
  //
  RedBase(PVector p, color c, Team t, int no) {
    super(p, c, t);
  }

  //
  // setup
  // =====
  // > called at the creation of the base
  //
  void setup() {
    // creates a new harvester
    newHarvester();
    // 3 more harvesters to create
    brain[5].x = 3;
    brain[5].y = 3;
    brain[5].z = 1;
    brain[0].x = -1;
    brain[0].y = -1;
    brain[0].z = 0;
    brain[1].x = -1;
    brain[1].y = -1;
    brain[1].z = 0;
  }

  //
  // go
  // ==
  // > called at each iteration of the game
  // > defines the behavior of the agent
  //
  void go() {
    // handle received messages 
    handleMessages();

    // creates new robots depending on energy and the state of brain[5]
    if ((brain[5].x > 0) && (energy >= 1000 + harvesterCost)) {
      // 1st priority = creates harvesters 
      if (newHarvester())
        brain[5].x--;
    } else if ((brain[5].y > 0) && (energy >= 1000 + launcherCost)) {
      // 2nd priority = creates rocket launchers 
      if (newRocketLauncher())
        brain[5].y--;
    } else if ((brain[5].z > 0) && (energy >= 1000 + explorerCost)) {
      // 3rd priority = creates explorers 
      if (newExplorer())
        brain[5].z--;
    } else if (energy > 12000) {
      // if no robot in the pipe and enough energy 
      if ((int)random(2) == 0)
        // creates a new harvester with 50% chance
        brain[5].x++;
      else if ((int)random(2) == 0)
        // creates a new rocket launcher with 25% chance
        brain[5].y++;
      else if (brain[1].x == -1)
        // creates a new explorer with 25% chance
        brain[5].z++;
    }

    if (brain[0].z == 2 && brain[1].z == 2){
      ArrayList Launchers = perceiveRobots(friend,LAUNCHER);
      if (Launchers != null){
       for( Object r : Launchers){
          recycle((Robot)r);
        }
      }
      
      
    }
    // creates new bullets and fafs if the stock is low and enought energy
    if ((bullets < 10) && (energy > 1000))
      newBullets(50);
    //if ((bullets < 10) && (energy > 1000))
    //  newFafs(10);
    
    //si il n'y a aucun LAUNCHER à proximité la base se défend elle même
    if (perceiveRobots(friend,LAUNCHER) == null){
      
    // if ennemy rocket launcher in the area of perception
    Robot bob = (Robot)minDist(perceiveRobots(ennemy, LAUNCHER));
    if (bob != null) {
      heading = towards(bob);
      // launch a faf if no friend robot on the trajectory...
      if (perceiveRobotsInCone(friend, heading) == null)
        launchFaf(bob);
    }
    }
    
    if (brain[0].x !=-1){
      //si une première base a été découverte, en informe les launchers alentours
      for( Object r : (perceiveRobots(friend,LAUNCHER))){
        informAboutXYTarget((Robot) r,new PVector(brain[0].x,brain[0].y));
      }      
    }
    if (brain[1].x !=-1){
      //si une deuxième base a été découverte, en informe les launchers alentours
      for( Object r : (perceiveRobots(friend,LAUNCHER))){
        informAboutXYTarget((Robot) r,new PVector(brain[1].x,brain[1].y));
      }
           
    }
  }
  


  //
  // handleMessage
  // =============
  // > handle messages received since last activation 
  //
  void handleMessages() {
    Message msg;
    // for all messages
    for (int i=0; i<messages.size(); i++) {
      msg = messages.get(i);
      if (msg.type == ASK_FOR_ENERGY) {
        // if the message is a request for energy
        if (energy > 1000 + msg.args[0]) {
          // gives the requested amount of energy only if at least 1000 units of energy left after
          giveEnergy(msg.agent, msg.args[0]);
        }
      } else if (msg.type == ASK_FOR_BULLETS) {
        // if the message is a request for energy
        if (energy > 1000 + msg.args[0] * bulletCost) {
          // gives the requested amount of bullets only if at least 1000 units of energy left after
          giveBullets(msg.agent, msg.args[0]);
        }
      } else if (msg.type == INFORM_ABOUT_TARGET){
        //stocke les coordonnées des bases ennemis pour ordonner aux missiles launchers d'aller attaquer la base
        if(msg.args[2] == BASE) {
          if (brain[0].x == -1) {
            brain[0].x = msg.args[0];
            brain[0].y = msg.args[1];
          }
          else if(brain[0].x != msg.args[0] && brain[0].y != msg.args[1] && brain[1].x != -1){
             brain[1].x = msg.args[0];
             brain[1].y = msg.args[1];
          }
        }
      }
      else if (msg.type == INFORM_ABOUT_XYTARGET){
        //stocke les coordonnées d'un base ennemie transférées depuis un explorer qui est revenu et qui n'a pas pu contacter la base au moment de partir
        if (brain[0].x == -1) {
          brain[0].x = msg.args[0];
          brain[0].y = msg.args[1];
        }
        else if(brain[0].x != msg.args[0] && brain[0].y != msg.args[1] && brain[1].x != -1){
          brain[1].x = msg.args[0];
          brain[1].y = msg.args[1];
        }   
      }
      //quand un LAUNCHER rentre de la base avec la le message targetDestroyed
      else if(msg.type == TARGET_DESTROYED){
        if (msg.args[0] == brain[0].x && msg.args[1] == brain[0].y){
          brain[0].z = 2;
         }
        if (msg.args[0] == brain[1].x && msg.args[1] == brain[1].y){
          brain[1].z = 2;
         }
        
      }
    }
    // clear the message queue
    flushMessages();
  }
}

///////////////////////////////////////////////////////////////////////////
//
// The code for the green explorers
//
///////////////////////////////////////////////////////////////////////////
// map of the brain:
//   4.x = (0 = exploration | 1 = go back to base)
//   4.y = (0 = no target | 1 = locked target)
//   0.x / 0.y = coordinates of the target
//   0.z = type of the target
///////////////////////////////////////////////////////////////////////////
class RedExplorer extends Explorer {
  //
  // constructor
  // ===========
  //
  RedExplorer(PVector pos, color c, ArrayList b, Team t) {
    super(pos, c, b, t);
  }

  //
  // setup
  // =====
  // > called at the creation of the agent
  //
  void setup() {
    brain[1].x = random(360);
    heading = brain[1].x;
    brain[1].y = 0;
    brain[2].x = brain[2].y = -1;
  }

  //
  // go
  // ==
  // > called at each iteration of the game
  // > defines the behavior of the agent
  //
  void go() {
    // if food to deposit or too few energy
    if ((carryingFood > 200) || (energy < 100) || brain[1].y == 1)
      // time to go back to base
      brain[4].x = 1;

    // depending on the state of the robot
    if (brain[4].x == 1) {
      // go back to base...
      goBackToBase();
      if (brain[2].x != -1){
        RocketLauncher rocky = (RocketLauncher)oneOf(perceiveRobots(friend, LAUNCHER));
        if (rocky != null)
          // if one is seen, send a message with the localized ennemy base
          informAboutXYTarget(rocky, brain[2]);
      }
    } else {
      // ...or explore in a defined straight line
      tryToMoveForward();
    }

    // tries to localize ennemy bases
    lookForEnnemyBase();
    // inform harvesters about food sources
    driveHarvesters();
    // inform rocket launchers about targets
    driveRocketLaunchers();

    // reads messages
    handleMessages();
    
    // clear the message queue
    flushMessages();
  }

  //
  // setTarget
  // =========
  // > locks a target
  //
  // inputs
  // ------
  // > p = the location of the target
  // > breed = the breed of the target
  //
  void setTarget(PVector p, int breed) {
    brain[0].x = p.x;
    brain[0].y = p.y;
    brain[0].z = breed;
    brain[4].y = 1;
  }

  //
  // goBackToBase
  // ============
  // > go back to the closest base, either to deposit food or to reload energy
  //
  void goBackToBase() {
    // bob is the closest base
    Base bob = (Base)minDist(myBases);
    if (bob != null) {
      // if there is one (not all of my bases have been destroyed)
      float dist = distance(bob);

      if (dist <= 2) {
        // if I am next to the base
        if (energy < 500)
          // if my energy is low, I ask for some more
          askForEnergy(bob, 1500 - energy);
        // switch to the exploration state
        brain[4].x = 0;
        // make a half turn
        brain[1].x = random(360);
        brain[1].y = 0;
      } else {
        // if still away from the base
        // head towards the base (with some variations if there is a wall in the way)...
        if(perceiveWallsInCone(10) != null){
          heading = towards(bob);
        }
        else{
          heading = towards(bob) + random(-radians(20), radians(20));
        }
        // ...and try to move forward 
        tryToMoveForward();
      }
    }
  }

  //
  // target
  // ======
  // > checks if a target has been locked
  //
  // output
  // ------
  // true if target locket / false if not
  //
  boolean target() {
    return (brain[4].y == 1);
  }

  //
  // driveHarvesters
  // ===============
  // > tell harvesters if food is localized
  //
  void driveHarvesters() {
    // look for burgers
    Burger zorg = (Burger)oneOf(perceiveBurgers());
    if (zorg != null) {
      // if one is seen, look for a friend harvester
      Harvester harvey = (Harvester)oneOf(perceiveRobots(friend, HARVESTER));
      if (harvey != null)
        // if a harvester is seen, send a message to it with the position of food
        informAboutFood(harvey, zorg.pos);
    }
  }

  //
  // driveRocketLaunchers
  // ====================
  // > tell rocket launchers about potential targets
  //
  void driveRocketLaunchers() {
    // look for an ennemy robot 
    Robot bob = (Robot)oneOf(perceiveRobots(ennemy));
    if (bob != null) {
      // if one is seen, look for a friend rocket launcher
      RocketLauncher rocky = (RocketLauncher)oneOf(perceiveRobots(friend, LAUNCHER));
      if (rocky != null)
        // if a rocket launcher is seen, send a message with the localized ennemy robot
        informAboutTarget(rocky, bob);
    }
  }

  //
  // lookForEnnemyBase
  // =================
  // > try to localize ennemy bases...
  // > ...and to communicate about this to other friend explorers
  //
  void lookForEnnemyBase() {
    // look for an ennemy base
    Base babe = (Base)oneOf(perceiveRobots(ennemy, BASE));
    if (babe != null) {
      // if one is seen, look for a friend explorer
      Explorer explo = (Explorer)oneOf(perceiveRobots(friend, EXPLORER));
      if (explo != null)
        // if one is seen, send a message with the localized ennemy base
        informAboutXYTarget(explo, babe.pos);
      // look for a friend base
      Base basy = (Base)oneOf(perceiveRobots(friend, BASE));
      if (basy != null)
        // if one is seen, send a message with the localized ennemy base
        informAboutTarget(basy, babe);
      // brain[2] is a reserved space for storing coordinates of a primary objective
      brain[2].x = babe.pos.x;
      brain[2].y = babe.pos.y;
      brain[1].y = 1;
    }
  }

  //
  // tryToMoveForward
  // ================
  // > try to move forward after having checked that no obstacle is in front
  //
  void tryToMoveForward() {
    // if there is an obstacle ahead, rotate randomly
    if (!freeAhead(speed))
      right(45+random(270));

    // if there is no obstacle ahead, move forward at full speed
    if (freeAhead(speed))
      forward(speed);
  }
  
  //
  // handleMessage
  // =============
  // > handle messages received since last activation 
  //
  void handleMessages() {
    Message msg;
    // for all messages
    for (int i=0; i<messages.size(); i++) {
      msg = messages.get(i);
      if (msg.type == INFORM_ABOUT_XYTARGET) {
        // if the message is information about coordinates, it is about a base so we take the information and keep on trying to bring it to the base as fast as possible
        brain[2].x = msg.args[0];
        brain[2].y = msg.args[1];
        brain[1].y = 1;
      }
    }
    flushMessages();
  }
}

///////////////////////////////////////////////////////////////////////////
//
// The code for the green harvesters
//
///////////////////////////////////////////////////////////////////////////
// map of the brain:
//   4.x = (0 = look for food | 1 = go back to base) 
//   4.y = (0 = no food found | 1 = food found)
//   0.x / 0.y = position of the localized food
///////////////////////////////////////////////////////////////////////////
class RedHarvester extends Harvester {
  //
  // constructor
  // ===========
  //
  RedHarvester(PVector pos, color c, ArrayList b, Team t) {
    super(pos, c, b, t);
  }

  //
  // setup
  // =====
  // > called at the creation of the agent
  //
  void setup() {
    
  }

  //
  // go
  // ==
  // > called at each iteration of the game
  // > defines the behavior of the agent
  //
  void go() {
    // handle messages received
    handleMessages();

    // check for the closest burger
    Burger b = (Burger)minDist(perceiveBurgers());
    if ((b != null) && (distance(b) <= 2))
      // if one is found next to the robot, collect it
      takeFood(b);

    // if food to deposit or too few energy
    if ((carryingFood > 200) || (energy < 100))
      // time to go back to the base
      brain[4].x = 1;

    // if in "go back" state
    if (brain[4].x == 1) {
      // go back to the base
      goBackToBase();

      // if enough energy and food
      if ((energy > 100) && (carryingFood > 100)) {
        // check for closest base
        Base bob = (Base)minDist(myBases);
        if (bob != null) {
          // if there is one and the harvester is in the sphere of perception of the base
          if (distance(bob) < basePerception)
            // plant one burger as a seed to produce new ones
            plantSeed();
        }
      }
    } else
      // if not in the "go back" state, explore and collect food
      goAndEat();
  }

  //
  // goBackToBase
  // ============
  // > go back to the closest friend base
  //
  void goBackToBase() {
    // look for the closest base
    Base bob = (Base)minDist(myBases);
    if (bob != null) {
      // if there is one
      float dist = distance(bob);
      if ((dist > basePerception) && (dist < basePerception + 1))
        // if at the limit of perception of the base, drops a wall (if it carries some)
        dropWall();

      if (dist <= 2) {
        // if next to the base, gives the food to the base
        giveFood(bob, carryingFood);
        if (energy < 500)
          // ask for energy if it lacks some
          askForEnergy(bob, 1500 - energy);
        // go back to "explore and collect" mode
        brain[4].x = 0;
        // make a half turn
        right(180);
      } else {
        // if still away from the base
        // head towards the base (with some variations)...
        heading = towards(bob) + random(-radians(20), radians(20));
        // ...and try to move forward
        tryToMoveForward();
      }
    }
  }

  //
  // goAndEat
  // ========
  // > go explore and collect food
  //
  void goAndEat() {
    // look for the closest wall
    Wall wally = (Wall)minDist(perceiveWalls());
    // look for the closest base
    Base bob = (Base)minDist(myBases);
    if (bob != null) {
      float dist = distance(bob);
      // if wall seen and not at the limit of perception of the base 
      if ((wally != null) && ((dist < basePerception - 1) || (dist > basePerception + 2)))
        // tries to collect the wall
        takeWall(wally);
    }

    // look for the closest burger
    Burger zorg = (Burger)minDist(perceiveBurgers());
    if (zorg != null) {
      // if there is one
      if (distance(zorg) <= 2)
        // if next to it, collect it
        takeFood(zorg);
      else {
        // if away from the burger, head towards it...
        heading = towards(zorg);
        // ...and try to move forward
        tryToMoveForward();
      }
    } else if (brain[4].y == 1) {
      // if no burger seen but food localized (thank's to a message received)
      if (distance(brain[0]) > 2) {
        // head towards localized food...
        heading = towards(brain[0]);
        // ...and try to move forward
        tryToMoveForward();
      } else
        // if the food is reached, clear the corresponding flag
        brain[4].y = 0;
    } else {
      // if no food seen and no food localized, explore randomly
      heading += random(-radians(20), radians(20));
      tryToMoveForward();
    }
  }

  //
  // tryToMoveForward
  // ================
  // > try to move forward after having checked that no obstacle is in front
  //
   void tryToMoveForward() {
    // if there is an obstacle ahead, rotate randomly
    if (!freeAhead(speed))
      right(45+random(270));

    // if there is no obstacle ahead, move forward at full speed
    if (freeAhead(speed))
      forward(speed);
  }

  //
  // handleMessages
  // ==============
  // > handle messages received
  // > identify the closest localized burger
  //
  void handleMessages() {
    float d = width;
    PVector p = new PVector();

    Message msg;
    // for all messages
    for (int i=0; i<messages.size(); i++) {
      // get next message
      msg = messages.get(i);
      // if "localized food" message
      if (msg.type == INFORM_ABOUT_FOOD) {
        // record the position of the burger
        p.x = msg.args[0];
        p.y = msg.args[1];
        if (distance(p) < d) {
          // if burger closer than closest burger
          // record the position in the brain
          brain[0].x = p.x;
          brain[0].y = p.y;
          // update the distance of the closest burger
          d = distance(p);
          // update the corresponding flag
          brain[4].y = 1;
        }
      }
    }
    // clear the message queue
    flushMessages();
  }
}

///////////////////////////////////////////////////////////////////////////
//
// The code for the green rocket launchers
//
///////////////////////////////////////////////////////////////////////////
// map of the brain:
//   0.x / 0.y = position of the target
//   0.z = breed of the target
//   4.x = (0 = look for target | 1 = go back to base| 2 = go back to base inform destroy) 
//   4.y = (0 = no target | 1 = localized target)
///////////////////////////////////////////////////////////////////////////
class RedRocketLauncher extends RocketLauncher {
  //
  // constructor
  // ===========
  //
  RedRocketLauncher(PVector pos, color c, ArrayList b, Team t) {
    super(pos, c, b, t);
  }

  //
  // setup
  // =====
  // > called at the creation of the agent
  //
  void setup() {
    brain[0].z = -1;
  }

  //
  // go
  // ==
  // > called at each iteration of the game
  // > defines the behavior of the agent
  //
  void informAboutTargetDestroyed(Robot bob){
    float[] args = new float[2];
      args[0] = brain[0].x;
      args[1] = brain[0].y;
      Message msg = new Message(TARGET_DESTROYED,who,args);
      bob.messages.add(msg);
  }
  void go() {
    //if the base target has been destroy 
    if (brain[4].x == 2){
      
            if (perceiveRobots(friend,BASE) != null){
              informAboutTargetDestroyed((Robot) oneOf(perceiveRobots(friend,BASE)));
            }
    }
    // if no energy or no bullets
    if ((energy < 100) || (bullets == 0))
      // go back to the base
      if (brain[4].x != 2) brain[4].x = 1;

    if (brain[4].x == 1 || brain[4].x == 2) {
      // if in "go back to base" mode
      goBackToBase();
    } else {
       handleMessages();
       //if LAUNCHER don't find the base change behavior to 2 (go back to base and inform the base)
       if(distance(new PVector(brain[0].x,brain[0].y)) < 5 &&  perceiveRobots(ennemy, BASE)== null ){
               brain[4].x = 2;  
               brain[0].z = -1;
       }
       //If target is a base we rush on it 
       if (brain[0].z == 0 && brain[4].x == 0){
         rush(brain[0].x,brain[0].y);
       }
       else{
      
      // try to find a target
      selectTarget();
      // if target identified
      if (target())
        // shoot on the target
        launchBullet(towards(brain[0]));
      else
        // else explore randomly
        randomMove(45);
    }
    
  }
 }
  
  void handleMessages() {
    Message msg;
    // for all messages
    for (int i=0; i<messages.size(); i++) {
      msg = messages.get(i);
      if (msg.type == INFORM_ABOUT_XYTARGET) {
        // if the message is information about coordinates, it is about a base so we take the information 
        brain[0].x = msg.args[0];
        brain[0].y = msg.args[1];
        brain[0].z = 0;
        brain[4].x = 0;
        brain[4].y = 1;
      }
    }
    flushMessages();
  }
  //
  //rush
  //============
  //>rush on the point x,y while ignoring other ennemy
  //
  void rush(float x, float y){
    ArrayList trg = perceiveRobots(ennemy, BASE);
    if (trg != null) {
      launchBullet(towards(brain[0]));
          }
    else{
       heading = towards(new PVector(x,y));
      }
    tryToMoveForward();
    }
    
  

  //
  // selectTarget
  // ============
  // > try to localize a target
  //
  void selectTarget() {
    // look for the closest ennemy robot
    Robot bob = (Robot)minDist(perceiveRobots(ennemy));
    if (bob != null) {
      // if one found, record the position and breed of the target
      brain[0].x = bob.pos.x;
      brain[0].y = bob.pos.y;
      brain[0].z = bob.breed;
      // locks the target
      brain[4].y = 1;
    } else
      // no target found
      brain[4].y = 0;
  }

  //
  // target
  // ======
  // > checks if a target has been locked
  //
  // output
  // ------
  // > true if target locket / false if not
  //
  boolean target() {
    return (brain[4].y == 1);
  }

  //
  // goBackToBase
  // ============
  // > go back to the closest base
  //
  void goBackToBase() {
    // look for closest base
    Base bob = (Base)minDist(myBases);
    if (bob != null) {
      // if there is one, compute its distance
      float dist = distance(bob);

      if (dist <= 2) {
        // if next to the base
        if (energy < 500)
          // if energy low, ask for some energy
          askForEnergy(bob, 1500 - energy);
        // go back to "exploration" mode
        brain[4].x = 0;
        // make a half turn
        right(180);
      } else {
        // if not next to the base, head towards it... 
        heading = towards(bob) + random(-radians(20), radians(20));
        // ...and try to move forward
        tryToMoveForward();
      }
    }
  }

  //
  // tryToMoveForward
  // ================
  // > try to move forward after having checked that no obstacle is in front
  //
  void tryToMoveForward() {
    // if there is an obstacle ahead, rotate randomly
    if (!freeAhead(speed,PI/4))
      right(45+random(270));

    // if there is no obstacle ahead, move forward at full speed
    if (freeAhead(speed,PI/4))
      forward(speed);
  }
}
