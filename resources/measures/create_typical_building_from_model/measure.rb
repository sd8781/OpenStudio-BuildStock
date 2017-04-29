# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class CreateTypicalBuildingFromModel < OpenStudio::Ruleset::ModelUserScript

  require 'openstudio-standards'

  # require all .rb files in resources folder
  Dir[File.dirname(__FILE__) + '/resources/*.rb'].each {|file| require file }

  # resource file modules
  include OsLib_HelperMethods
  include OsLib_ModelGeneration

  # human readable name
  def name
    return "Create Typical Building from Model"
  end

  # human readable description
  def description
    return "Takes a model with space and stub space types, and assigns constructions, schedules, internal loads, hvac, and other loads such as exterior lights and service water heating. The end result is somewhat like a custom protptye model with user geometry, but it may use different HVAC systems."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Initially this was intended for stub space types, but it is possible that it will be run on models tha talready have internal loads, schedules, or constructions that should be preserved. Set it up to support addition at later date of bool args to skip specific types of model elements."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    # see if building name contains any template values
    default_string = '90.1-2010'
    get_templates().each do |template_string|
      if model.getBuilding.name.to_s.include?(template_string)
        default_string = template_string
        next
      end
    end

    # Make argument for template
    template = OpenStudio::Ruleset::OSArgument::makeChoiceArgument('template', get_templates(), true)
    template.setDisplayName('Target Standard')
    template.setDefaultValue(default_string)
    args << template

    # Make argument for building_type
    bldg_type_chs = OpenStudio::StringVector.new
    bldg_type_chs << "SecondarySchool"
    bldg_type_chs << "PrimarySchool"
    bldg_type_chs << "SmallOffice"
    bldg_type_chs << "MediumOffice"
    bldg_type_chs << "LargeOffice"
    bldg_type_chs << "SmallHotel"
    bldg_type_chs << "LargeHotel"
    bldg_type_chs << "Warehouse"
    bldg_type_chs << "RetailStandalone"
    bldg_type_chs << "RetailStripmall"
    bldg_type_chs << "QuickServiceRestaurant"
    bldg_type_chs << "FullServiceRestaurant"
    bldg_type_chs << "MidriseApartment"
    bldg_type_chs << "HighriseApartment"
    bldg_type_chs << "Hospital"
    bldg_type_chs << "Outpatient"
    bldg_type_chs << "SuperMarket"
    building_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument('building_type', bldg_type_chs, true)
    building_type.setDisplayName('Primary Building Type')
    building_type.setDescription('The building type that makes up a majority of the area.  Used for HVAC assumptions.')
    building_type.setDefaultValue('SmallOffice')
    args << building_type

    # Make argument for system type
    hvac_chs = OpenStudio::StringVector.new
    hvac_chs << "Inferred"
    hvac_chs << "Ideal Air Loads"
    hvac_chs << "PTAC w/ hot water heat"
    hvac_chs << "PTAC w/ gas coil heat"
    hvac_chs << "PTAC w/ electric baseboard heat"
    hvac_chs << "PTAC w/ no heat"
    hvac_chs << "PTAC w/ district hot water heat"
    hvac_chs << "PTHP"
    hvac_chs << "PSZ-AC w/ gas coil heat"
    hvac_chs << "PSZ-AC w/ electric baseboard heat"
    hvac_chs << "PSZ-AC w/ no heat"
    hvac_chs << "PSZ-AC w/district hot water heat"
    hvac_chs << "PSZ-HP"
    hvac_chs << "Fan coil district chilled water w/ no heat"
    hvac_chs << "Fan coil district chilled water and boiler"
    hvac_chs << "Fan coil district chilled water unit heaters"
    hvac_chs << "Fan coil district chilled water electric baseboard heat"
    hvac_chs << "Fan coil district hot and cold water"
    hvac_chs << "Fan coil district hot water and chiller"
    hvac_chs << "Fan coil chiller w/ no heat"
    hvac_chs << "Baseboard district hot water heat"
    hvac_chs << "Baseboard district hot water heat w/ direct evap coolers"
    hvac_chs << "Baseboard electric heat"
    hvac_chs << "Baseboard electric heat w/ direct evap coolers"
    hvac_chs << "Baseboard hot water heat"
    hvac_chs << "Baseboard hot water heat w/ direct evap coolers"
    hvac_chs << "Window AC w/ no heat"
    hvac_chs << "Window AC w/ forced air furnace"
    hvac_chs << "Window AC w/ district hot water baseboard heat"
    hvac_chs << "Window AC w/ hot water baseboard heat"
    hvac_chs << "Window AC w/ electric baseboard heat"
    hvac_chs << "Window AC w/ unit heaters"
    hvac_chs << "Direct evap coolers"
    hvac_chs << "Direct evap coolers w/ unit heaters"
    hvac_chs << "Unit heaters"
    hvac_chs << "Heat pump heating w/ no cooling"
    hvac_chs << "Heat pump heating w/ direct evap cooler"
    hvac_chs << "VAV w/ reheat"
    hvac_chs << "PVAV w/ reheat"
    hvac_chs << "PVAV w/ PFP boxes"
    hvac_chs << "Residential forced air"
    system_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("system_type", hvac_chs,true)
    system_type.setDisplayName("HVAC System Type")
    system_type.setDescription("The HVAC system that will be put into the model.")
    system_type.setDefaultValue("Inferred")
    args << system_type

    # Make argument for HVAC delivery type
    hvac_type_chs = OpenStudio::StringVector.new
    hvac_type_chs << "Forced Air"
    hvac_type_chs << "Hydronic"
    hvac_delivery_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("hvac_delivery_type", hvac_type_chs,true)
    hvac_delivery_type.setDisplayName("HVAC System Delivery Type")
    hvac_delivery_type.setDescription("How the HVAC system delivers heating or cooling to the zone.  Only used if HVAC System Type is Inferred. ")
    hvac_delivery_type.setDefaultValue("Forced Air")
    args << hvac_delivery_type

    # Make argument for HVAC heating source
    htg_src_chs = OpenStudio::StringVector.new
    htg_src_chs << "Electricity"
    htg_src_chs << "NaturalGas"
    htg_src_chs << "DistrictHeating"
    htg_src_chs << "DistrictAmbient"
    htg_src = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("htg_src", htg_src_chs,true)
    htg_src.setDisplayName("HVAC Heating Source")
    htg_src.setDescription("The primary source of heating used by HVAC systems in the model.  Only used if HVAC System Type is Inferred.")
    htg_src.setDefaultValue("NaturalGas")
    args << htg_src
    
    # Make argument for HVAC cooling source
    clg_src_chs = OpenStudio::StringVector.new
    clg_src_chs << "Electricity"
    clg_src_chs << "DistrictCooling"
    clg_src_chs << "DistrictAmbient"
    clg_src = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("clg_src", clg_src_chs,true)
    clg_src.setDisplayName("HVAC Cooling Source")
    clg_src.setDescription("The primary source of cooling used by HVAC systems in the model.  Only used if HVAC System Type is Inferred.")
    clg_src.setDefaultValue("Electricity")
    args << clg_src

    # fuel choices for multiple arguments
    fuel_choices = OpenStudio::StringVector.new
    fuel_choices << "Electric"
    fuel_choices << "Gas"
    fuel_choices << "Infer from HVAC System Type"

    # make argument for fuel type (not used yet)
    fuel_type_swh = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("fuel_type_swh", fuel_choices,true)
    fuel_type_swh.setDisplayName("Fuel Type for Service Water Heating Supply")
    fuel_type_swh.setDefaultValue("Infer from HVAC System Type")
    args << fuel_type_swh

    # make argument for fuel type (not used yet)
    fuel_type_cooking = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("fuel_type_cooking", fuel_choices,true)
    fuel_type_cooking.setDisplayName("Fuel Type for Cooking Loads")
    fuel_type_cooking.setDefaultValue("Gas")
    args << fuel_type_cooking

    # make argument for fuel type (not used yet)
    fuel_type_laundry = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("fuel_type_laundry", fuel_choices,true)
    fuel_type_laundry.setDisplayName("Fuel Type for Laundry Dryer Loads")
    fuel_type_laundry.setDefaultValue("Electric")
    args << fuel_type_laundry

    # make argument for kitchen makeup
    kitchen_makeup_choices = OpenStudio::StringVector.new
    kitchen_makeup_choices << "None"
    kitchen_makeup_choices << "Largest Zone"
    kitchen_makeup_choices << "Adjacent"
    kitchen_makeup = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("kitchen_makeup", kitchen_makeup_choices,true)
    kitchen_makeup.setDisplayName("Kitchen Exhaust MakeUp Air Calculation Method")
    kitchen_makeup.setDescription("Determine logic to identify dining or cafe zones to provide makeup air to kitchen exhaust.")
    kitchen_makeup.setDefaultValue("Adjacent")
    args << kitchen_makeup

    # make argument for exterior_lighting_zone
    exterior_lighting_zone_choices = OpenStudio::StringVector.new
    exterior_lighting_zone_choices << "0 - Undeveloped Areas Parks"
    exterior_lighting_zone_choices << "1 - Developed Areas Parks"
    exterior_lighting_zone_choices << "2 - Neighborhood"
    exterior_lighting_zone_choices << "3 - All Other Areas"
    exterior_lighting_zone_choices << "4 - High Activity"
    exterior_lighting_zone = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("exterior_lighting_zone", exterior_lighting_zone_choices,true)
    exterior_lighting_zone.setDisplayName("Exterior Lighting Zone")
    exterior_lighting_zone.setDescription("Identify the Exterior Lighitng Zone for the Building Site.")
    exterior_lighting_zone.setDefaultValue("3 - All Other Areas")
    args << exterior_lighting_zone

    #make an argument for add_elevators
    add_elevators = OpenStudio::Ruleset::OSArgument::makeBoolArgument("add_elevators",true)
    add_elevators.setDisplayName("Add Elevators to Model")
    add_elevators.setDescription("Elevators will be add directly to space in model vs. being applied to a space type.")
    add_elevators.setDefaultValue(true)
    args << add_elevators

    #make an argument for add_exterior_lights
    add_exterior_lights = OpenStudio::Ruleset::OSArgument::makeBoolArgument("add_exterior_lights",true)
    add_exterior_lights.setDisplayName("Add Exterior Lights to Model")
    add_exterior_lights.setDescription("Multiple exterior lights objects will be added for different classes of lighting such as parking and facade.")
    add_exterior_lights.setDefaultValue(true)
    args << add_exterior_lights

    #make an argument for add_exhaust
    add_exhaust = OpenStudio::Ruleset::OSArgument::makeBoolArgument("add_exhaust",true)
    add_exhaust.setDisplayName("Add Exhaust Fans to Model")
    add_exhaust.setDescription("Depending upon building type exhaust fans can be in kitchens, restrooms or other space types")
    add_exhaust.setDefaultValue(true)
    args << add_exhaust

    #make an argument for add_swh
    add_swh = OpenStudio::Ruleset::OSArgument::makeBoolArgument("add_swh",true)
    add_swh.setDisplayName("Add Service Water Heating to Model")
    add_swh.setDescription("This will add both the supply and demand side of service water heating.")
    add_swh.setDefaultValue(true)
    args << add_swh

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # assign the user inputs to variables
    args  = OsLib_HelperMethods.createRunVariables(runner, model,user_arguments, arguments(model))
    if !args then return false end

    # look at upstream measure for 'template' argument
    # todo - in future make template in this measure an optinal argument and only override value when it is not initialized. There may be valid use cases for using different template values in different measures within the same workflow.
    template_value_from_osw  = OsLib_HelperMethods.check_upstream_measure_for_arg(runner, 'template')
    if template_value_from_osw.size > 0
      runner.registerInfo("Replacing argument named 'template' from current measure with a value of #{template_value_from_osw[:value]} from #{template_value_from_osw[:measure_name]}.")
      args['template'] = template_value_from_osw[:value]
    end

    # look at upstream measure for 'building_type' argument
    # todo - in future make building_type in this measure an optinal argument and only override value when it is not initialized.
    building_type_value_from_osw  = OsLib_HelperMethods.check_upstream_measure_for_arg(runner, 'building_type')
    if building_type_value_from_osw.size > 0
      runner.registerInfo("Replacing argument named 'building_type' from current measure with a value of #{building_type_value_from_osw[:value]} from #{building_type_value_from_osw[:measure_name]}.")
      args['building_type'] = building_type_value_from_osw[:value]
    end

    # report initial condition of model
    initial_objects = model.getModelObjects.size
    runner.registerInitialCondition("The building started with #{initial_objects} objects.")

    # remove everything but spaces, zones, and stub space types (extend as needed for additional objects, may make bool arg for this)
    model.getSpaceLoads.each { |i| i.remove }
    model.getThermostatSetpointDualSetpoints.each { |i| i.remove }
    model.getDefaultScheduleSets.each { |i| i.remove }
    model.getDefaultConstructionSets.each { |i| i.remove }
    model.getExteriorLightss.each { |i| i.remove }
    model.getLoops.each { |i| i.remove }
    model.getZoneHVACComponents.each { |i| i.remove }
    model.getRefrigerationSystems.each { |i| i.remove }
    model.getWaterUseEquipments.each { |i| i.remove }
    model.getWaterUseConnectionss.each { |i| i.remove }
    model.purgeUnusedResourceObjects
    objects_after_cleanup = initial_objects - model.getModelObjects.size
    if objects_after_cleanup > 0
      runner.registerInfo("Removing #{objects_after_cleanup} objects from model")
    end

    # open channel to log messages
    OsLib_HelperMethods.setup_log_msgs(runner)

    # add internal loads to space types
    building_types = {}
    model.getSpaceTypes.each do |space_type|
      test = space_type.apply_internal_loads(args['template'],true,true,true,true,true,true)
      if test.nil?
        runner.registerWarning("Could not add loads for #{space_type.name}. Not expected for #{args['template']}")
        next
      end

      # apply internal load schedules
      # the last bool test it to make thermostat schedules. They are added to the model but not assigned
      space_type.apply_internal_load_schedules(args['template'],true,true,true,true,true,true,true)

      # extend space type name to include the args['template']. Consider this as well for load defs
      space_type.setName("#{space_type.name.to_s} - #{args['template']}")
      runner.registerInfo("Adding loads to space type named #{space_type.name}")

      # identify thermal thermostat and apply to zones
      standards_space_type = space_type.standardsSpaceType
      model.getThermostatSetpointDualSetpoints.each do |thermostat|
        next if not standards_space_type.is_initialized
        next if not thermostat.name.to_s.include?(standards_space_type.get)
        runner.registerInfo("Assigning #{thermostat.name} to thermal zones with #{space_type.name} assigned.")
        space_type.spaces.each do |space|
          next if not space.thermalZone.is_initialized
          space.thermalZone.get.setThermostatSetpointDualSetpoint(thermostat)
        end
        next
      end

      # populate hash of building types
      if space_type.standardsBuildingType.is_initialized
        bldg_type = space_type.standardsBuildingType.get
        if not building_types.has_key?(bldg_type)
          building_types[bldg_type] = space_type.floorArea
        else
          building_types[bldg_type] += space_type.floorArea
        end
      else
        runner.registerWarning("Can't identify building type for #{space_type.name}")
      end

    end

    # warn if spaces in model without space type
    spaces_without_space_types = []
    model.getSpaces.each do |space|
      next if space.spaceType.is_initialized
      spaces_without_space_types << space
    end
    if spaces_without_space_types.size > 0
      runner.registerWarning("#{spaces_without_space_types.size} spaces do not have space types assigned, and wont' receive internal loads from standards space type lookups.")
    end

    # make construction set and apply to building
    # todo - allow building type and space type specific constructions set selection.
    primary_bldg_type = building_types.key(building_types.values.max) # todo - this fails if no space types, or maybe just no space types with standards
    model.getBuilding.setStandardsBuildingType(primary_bldg_type)
    if ['SmallHotel','LargeHotel','MidriseApartment','HighriseApartment'].include?(primary_bldg_type)
      is_residential = 'Yes'
    else
      is_residential = 'No'
    end
    climate_zone = model.get_building_climate_zone_and_building_type['climate_zone']
    bldg_def_const_set = model.add_construction_set(args['template'], climate_zone, primary_bldg_type, nil, is_residential)
    if bldg_def_const_set.is_initialized
      bldg_def_const_set = bldg_def_const_set.get
      if is_residential then bldg_def_const_set.setName("Res #{bldg_def_const_set.name}") end
      model.getBuilding.setDefaultConstructionSet(bldg_def_const_set)
      runner.registerInfo("Adding default construction set named #{bldg_def_const_set.name}")
    else
      runner.registerError('Could not create default construction set for the building.')
      return false
    end

    # address any adiabatic surfaces that don't have hard assigned constructions
    model.getSurfaces.each do |surface|
      next if not surface.outsideBoundaryCondition == "Adiabatic"
      next if surface.construction.is_initialized
      surface.setAdjacentSurface(surface)
      surface.setConstruction(surface.construction.get)
      surface.setOutsideBoundaryCondition("Adiabatic")
    end

    # add elevators (returns ElectricEquipment object)
    if args['add_elevators']
      elevators = model.add_elevators(args['template'])
      if elevators.nil?
        runner.registerInfo("No elevators added to the building.")
      else
        elevator_def = elevators.electricEquipmentDefinition
        design_level = elevator_def.designLevel.get
        runner.registerInfo("Adding #{elevators.multiplier.round(1)} elevators each with power of #{OpenStudio::toNeatString(design_level,0,true)} (W), plus lights and fans.")
      end
    end

    # add exterior lights (returns a hash where key is lighting type and value is exteriorLights object)
    if args['add_exterior_lights']
      exterior_lights = model.add_typical_exterior_lights(args['template'],args['exterior_lighting_zone'].chars[0].to_i)
      exterior_lights.each do |k,v|
        runner.registerInfo("Adding Exterior Lights named #{v.exteriorLightsDefinition.name} with design level of #{v.exteriorLightsDefinition.designLevel} * #{OpenStudio::toNeatString(v.multiplier,0,true)}.")
      end
    end

    # add_exhaust
    if args['add_exhaust']
      zone_exhaust_fans = model.add_exhaust(args['template'],args['kitchen_makeup']) # second argument is strategy for finding makeup zones for exhaust zones
      zone_exhaust_fans.each do |k,v|
        max_flow_rate_ip = OpenStudio::convert(k.maximumFlowRate.get,"m^3/s","cfm").get
        if v.has_key?(:zone_mixing)
          zone_mixing = v[:zone_mixing]
          mixing_source_zone_name = zone_mixing.sourceZone.get.name
          mixing_design_flow_rate_ip = OpenStudio::convert(zone_mixing.designFlowRate.get,"m^3/s","cfm").get
          runner.registerInfo("Adding #{OpenStudio::toNeatString(max_flow_rate_ip,0,true)} (cfm) of exhaust to #{k.thermalZone.get.name}, with #{OpenStudio::toNeatString(mixing_design_flow_rate_ip,0,true)} (cfm) of makeup air from #{mixing_source_zone_name}")
        else
          runner.registerInfo("Adding #{OpenStudio::toNeatString(max_flow_rate_ip,0,true)} (cfm) of exhaust to #{k.thermalZone.get.name}")
        end
      end
    end

    # add service water heating demand and supply
    if args['add_swh']
      typical_swh = model.add_typical_swh(args['template'])
      midrise_swh_loops = []
      stripmall_swh_loops = []
      typical_swh.each do |loop|
        if loop.name.get.include?("MidriseApartment")
          midrise_swh_loops << loop
        elsif loop.name.get.include?("RetailStripmall")
          stripmall_swh_loops << loop
        else
          water_use_connections = []
          loop.demandComponents.each do |component|
            next if not component.to_WaterUseConnections.is_initialized
            water_use_connections << component
          end
          runner.registerInfo("Adding #{loop.name} to the building. It has #{water_use_connections.size} water use connections.")
        end
      end
      if midrise_swh_loops.size > 0
        runner.registerInfo("Adding #{midrise_swh_loops.size} MidriseApartment service water heating loops.")
      end
      if stripmall_swh_loops.size > 0
        runner.registerInfo("Adding #{stripmall_swh_loops.size} RetailStripmall service water heating loops.")
      end
    end

    # todo - when add methods below add bool to enable/disable them with default value to true


    # todo - add daylight controls


    # todo - add refrigeration


    # todo - add internal mass


    # todo - add slab modeling and slab insulation


    # todo - fuel customization for cooking and laundry
    # works by switching some fraction of electric loads to gas if requested (assuming base load is electric)

    # add hvac system (should this have a bool to skip
    case args['system_type']
    when 'Inferred'
    
      # Determine the number of stories
      num_stories = model.effective_num_stories[:above_grade]

      # Get the hvac delivery type enum
      hvac_delivery = case args['hvac_delivery_type']
                      when 'Forced Air'
                        'air'
                      when 'Hydronic'
                        'hydronic'
                      end

      # Get the area and determine if primarily res or nonres
      areas = model.residential_and_nonresidential_floor_areas(args['template'])
      area_type = if areas['residential'] > areas['nonresidential']
                    'residential'
                  else
                    'nonresidential'
                  end
      area_m2 = areas['residential'] + areas['nonresidential']
            
      # Infer the HVAC system type
      sys_type, central_htg_fuel, zone_htg_fuel, clg_fuel = model.typical_hvac_system_type(args['template'],
                                                                                           climate_zone,
                                                                                           area_type,
                                                                                           hvac_delivery,
                                                                                           args['htg_src'],
                                                                                           args['clg_src'],
                                                                                           area_m2,
                                                                                           num_stories)

      # Group the zones by story
      story_groups = model.group_zones_by_story(model.getThermalZones)
      
      # Add the inferred HVAC system for each story.
      # Single-zone systems will get one per zone.
      story_groups.each do |zones|
        model.add_hvac_system(args['template'], sys_type, central_htg_fuel, zone_htg_fuel, clg_fuel, zones)
      end

    else

      # Group the zones by story
      story_groups = model.group_zones_by_story(model.getThermalZones)
      
      # Add the user specified HVAC system for each story.
      # Single-zone systems will get one per zone.
      story_groups.each do |zones|
        model.add_cbecs_hvac_system(args['template'], args['system_type'], zones)
      end

    end

    # todo - hours of operation customization (initially using existing measure downstream of this one)
    # not clear yet if this is altering existing schedules, or additional inputs when schedules first requested

    # set hvac controls and efficiencies (this should be last model articulation element)
    case args['system_type']
    when "Inferred", "Ideal Air Loads"
    
    else
      # Set the heating and cooling sizing parameters
      model.apply_prm_sizing_parameters

      # Perform a sizing run
      if model.runSizingRun("#{Dir.pwd}/SR1") == false
        return false
      end

      # Apply the prototype HVAC assumptions
      model.apply_prototype_hvac_assumptions(args['building_type'], args['template'], climate_zone)
 
      # Apply the HVAC efficiency standard
      model.apply_hvac_efficiency_standard(args['template'], climate_zone)
    end

    # report final condition of model
    runner.registerFinalCondition("The building finished with #{model.getModelObjects.size} objects.")

    # log messages to info messages
    OsLib_HelperMethods.log_msgs

    return true

  end
  
end

# register the measure to be used by the application
CreateTypicalBuildingFromModel.new.registerWithApplication
