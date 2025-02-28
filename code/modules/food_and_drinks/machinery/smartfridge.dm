// -------------------------
//  SmartFridge.  Much todo
// -------------------------
/obj/machinery/smartfridge
	name = "smartfridge"
	desc = "Keeps cold things cold and hot things cold."
	icon = 'icons/obj/machines/smartfridge.dmi'
	icon_state = "smartfridge"
	layer = BELOW_OBJ_LAYER
	density = TRUE
	circuit = /obj/item/circuitboard/machine/smartfridge
	light_power = 1
	light_range = MINIMUM_USEFUL_LIGHT_RANGE
	integrity_failure = 0.5
	can_atmos_pass = ATMOS_PASS_NO
	/// What path boards used to construct it should build into when dropped. Needed so we don't accidentally have them build variants with items preloaded in them.
	var/base_build_path = /obj/machinery/smartfridge
	/// Maximum number of items that can be loaded into the machine
	var/max_n_of_items = 1500
	/// The overlay for this fridge when it is filled with stuff
	var/contents_icon_state = "plant"
	/// List of items that the machine starts with upon spawn
	var/list/initial_contents
	/// If the machine shows an approximate number of its contents on its sprite
	var/visible_contents = TRUE
	/// Is this smartfridge going to have a glowing screen? (Drying Racks are not)
	var/has_emissive = TRUE
	/// Whether the smartfridge is welded down to the floor disabling unwrenching
	var/welded_down = FALSE

/obj/machinery/smartfridge/Initialize(mapload)
	. = ..()
	create_reagents(100, NO_REACT)
	air_update_turf(TRUE, TRUE)
	register_context()
	if(mapload)
		welded_down = TRUE

	if(islist(initial_contents))
		for(var/typekey in initial_contents)
			var/amount = initial_contents[typekey]
			if(isnull(amount))
				amount = 1
			for(var/i in 1 to amount)
				load(new typekey(src))

/obj/machinery/smartfridge/Move(atom/newloc, direct, glide_size_override, update_dir)
	var/turf/old_loc = loc
	. = ..()
	move_update_air(old_loc)

/obj/machinery/smartfridge/welder_act(mob/living/user, obj/item/tool)
	if(welded_down)
		if(!tool.tool_start_check(user, amount=2))
			return ITEM_INTERACT_BLOCKING

		user.visible_message(
			span_notice("[user.name] starts to cut the [name] free from the floor."),
			span_notice("You start to cut [src] free from the floor..."),
			span_hear("You hear welding."),
		)

		if(!tool.use_tool(src, user, delay=100, volume=100))
			return ITEM_INTERACT_BLOCKING

		welded_down = FALSE
		to_chat(user, span_notice("You cut [src] free from the floor."))
		return ITEM_INTERACT_SUCCESS

	if(!anchored)
		balloon_alert(user, "wrench it first!")
		return ITEM_INTERACT_BLOCKING

	if(!tool.tool_start_check(user, amount=2))
		return ITEM_INTERACT_BLOCKING

	user.visible_message(
		span_notice("[user.name] starts to weld the [name] to the floor."),
		span_notice("You start to weld [src] to the floor..."),
		span_hear("You hear welding."),
	)

	if(!tool.use_tool(src, user, delay = 100, volume = 100))
		return ITEM_INTERACT_BLOCKING

	welded_down = TRUE
	to_chat(user, span_notice("You weld [src] to the floor."))
	return ITEM_INTERACT_SUCCESS

/obj/machinery/smartfridge/welder_act_secondary(mob/living/user, obj/item/tool)
	if(!(machine_stat & BROKEN))
		balloon_alert(user, "no repair needed!")
		return ITEM_INTERACT_BLOCKING

	if(!tool.tool_start_check(user, amount=1))
		return ITEM_INTERACT_BLOCKING

	user.visible_message(
		span_notice("[user] is repairing [src]."),
		span_notice("You begin repairing [src]..."),
		span_hear("You hear welding."),
	)

	if(tool.use_tool(src, user, delay = 40, volume = 50))
		if(!(machine_stat & BROKEN))
			return ITEM_INTERACT_BLOCKING
		to_chat(user, span_notice("You repair [src]"))
		atom_integrity = max_integrity
		set_machine_stat(machine_stat & ~BROKEN)
		update_icon()
	return ITEM_INTERACT_SUCCESS

/obj/machinery/smartfridge/screwdriver_act(mob/living/user, obj/item/tool)
	if(default_deconstruction_screwdriver(user, icon_state, icon_state, tool))
		if(panel_open)
			add_overlay("[initial(icon_state)]-panel")
		else
			cut_overlay("[initial(icon_state)]-panel")
		SStgui.update_uis(src)
		return ITEM_INTERACT_SUCCESS
	return ITEM_INTERACT_BLOCKING

/obj/machinery/smartfridge/can_be_unfasten_wrench(mob/user, silent)
	if(welded_down)
		balloon_alert(user, "unweld first!")
		return FAILED_UNFASTEN
	return ..()

/obj/machinery/smartfridge/set_anchored(anchorvalue)
	. = ..()
	if(!anchored && welded_down) //make sure they're keep in sync in case it was forcibly unanchored by badmins or by a megafauna.
		welded_down = FALSE
	can_atmos_pass = anchorvalue ? ATMOS_PASS_NO : ATMOS_PASS_YES
	air_update_turf(TRUE, anchorvalue)

/obj/machinery/smartfridge/wrench_act(mob/living/user, obj/item/tool)
	if(default_unfasten_wrench(user, tool) == SUCCESSFUL_UNFASTEN)
		power_change()
		return ITEM_INTERACT_SUCCESS

/obj/machinery/smartfridge/crowbar_act(mob/living/user, obj/item/tool)
	if(default_pry_open(tool, close_after_pry = TRUE))
		return ITEM_INTERACT_SUCCESS

	if(welded_down)
		balloon_alert(user, "unweld first!")
	else
		default_deconstruction_crowbar(tool)
	return ITEM_INTERACT_SUCCESS

/obj/machinery/smartfridge/add_context(atom/source, list/context, obj/item/held_item, mob/living/user)
	if(isnull(held_item))
		return NONE

	var/tool_tip_set = FALSE
	if(held_item.tool_behaviour == TOOL_WELDER)
		if(welded_down)
			context[SCREENTIP_CONTEXT_LMB] = "Unweld"
			tool_tip_set = TRUE
		else if (!welded_down && anchored)
			context[SCREENTIP_CONTEXT_LMB] = "Weld down"
			tool_tip_set = TRUE
		if(machine_stat & BROKEN)
			context[SCREENTIP_CONTEXT_RMB] = "Repair"
			tool_tip_set = TRUE

	else if(held_item.tool_behaviour == TOOL_SCREWDRIVER)
		context[SCREENTIP_CONTEXT_LMB] = "[panel_open ? "close" : "open"] panel"
		tool_tip_set = TRUE

	else if(held_item.tool_behaviour == TOOL_CROWBAR)
		if(panel_open)
			context[SCREENTIP_CONTEXT_LMB] = "Deconstruct"
			tool_tip_set = TRUE

	else if(held_item.tool_behaviour == TOOL_WRENCH)
		context[SCREENTIP_CONTEXT_LMB] = "[anchored ? "Un" : ""]anchore"
		tool_tip_set = TRUE

	return tool_tip_set ? CONTEXTUAL_SCREENTIP_SET : NONE

/obj/machinery/smartfridge/RefreshParts()
	. = ..()
	for(var/datum/stock_part/matter_bin/matter_bin in component_parts)
		max_n_of_items = 1500 * matter_bin.tier

/obj/machinery/smartfridge/examine(mob/user)
	. = ..()

	if(in_range(user, src) || isobserver(user))
		. += span_notice("The status display reads: This unit can hold a maximum of <b>[max_n_of_items]</b> items.")

	. += structure_examine()

/// Returns details related to the fridge structure
/obj/machinery/smartfridge/proc/structure_examine()
	. = ""

	if(welded_down)
		. += span_info("It's moorings are firmly [EXAMINE_HINT("welded")] to the floor.")
	else
		. += span_info("It's moorings are loose and can be [EXAMINE_HINT("welded")] down.")

	if(anchored)
		. += span_info("It is [EXAMINE_HINT("wrenched")] down on the floor.")
	else
		. += span_info("It could be [EXAMINE_HINT("wrenched")] down.")

/obj/machinery/smartfridge/update_appearance(updates=ALL)
	. = ..()

	set_light((!(machine_stat & BROKEN) && powered()) ? MINIMUM_USEFUL_LIGHT_RANGE : 0)

/obj/machinery/smartfridge/update_icon_state()
	icon_state = "[initial(icon_state)]"
	if(machine_stat & BROKEN)
		icon_state += "-broken"
	else if(!powered())
		icon_state += "-off"
	return ..()

/// Returns the number of items visible in the fridge. Faster than subtracting 2 lists
/obj/machinery/smartfridge/proc/visible_items()
	return contents.len - 1 // Circuitboard

/obj/machinery/smartfridge/update_overlays()
	. = ..()

	var/shown_contents_length = visible_items()
	if(visible_contents && shown_contents_length)
		var/content_level = "[initial(icon_state)]-[contents_icon_state]"
		switch(shown_contents_length)
			if(1 to 25)
				content_level += "-1"
			if(26 to 50)
				content_level += "-2"
			if(31 to INFINITY)
				content_level += "-3"
		. += mutable_appearance(icon, content_level)

	. += mutable_appearance(icon, "[initial(icon_state)]-glass[(machine_stat & BROKEN) ? "-broken" : ""]")

	if(!machine_stat && has_emissive)
		. += emissive_appearance(icon, "[initial(icon_state)]-light-mask", src, alpha = src.alpha)

/obj/machinery/smartfridge/play_attack_sound(damage_amount, damage_type = BRUTE, damage_flag = 0)
	switch(damage_type)
		if(BRUTE)
			playsound(src.loc, 'sound/effects/glasshit.ogg', 75, TRUE)
		if(BURN)
			playsound(src.loc, 'sound/items/welder.ogg', 100, TRUE)

/obj/machinery/smartfridge/atom_break(damage_flag)
	playsound(src, SFX_SHATTER, 50, TRUE)
	return ..()

/obj/machinery/smartfridge/attackby(obj/item/weapon, mob/living/user, params)
	if(!machine_stat)
		var/shown_contents_length = visible_items()
		if(shown_contents_length >= max_n_of_items)
			balloon_alert(user, "no space!")
			return FALSE

		if(!(weapon.item_flags & ABSTRACT) && \
			!(weapon.flags_1 & HOLOGRAM_1) && \
			accept_check(weapon) \
		)
			load(weapon)
			user.visible_message(span_notice("[user] adds \the [weapon] to \the [src]."), span_notice("You add \the [weapon] to \the [src]."))
			SStgui.update_uis(src)
			if(visible_contents)
				update_appearance()
			return TRUE

		if(istype(weapon, /obj/item/storage/bag))
			var/obj/item/storage/bag = weapon
			var/loaded = 0
			for(var/obj/item/object in bag.contents)
				if(shown_contents_length >= max_n_of_items)
					break
				if(!(object.item_flags & ABSTRACT) && \
					!(object.flags_1 & HOLOGRAM_1) && \
					accept_check(object) \
				)
					load(object)
					loaded++
			SStgui.update_uis(src)

			if(loaded)
				if(shown_contents_length >= max_n_of_items)
					user.visible_message(span_notice("[user] loads \the [src] with \the [weapon]."), \
						span_notice("You fill \the [src] with \the [weapon]."))
				else
					user.visible_message(span_notice("[user] loads \the [src] with \the [weapon]."), \
						span_notice("You load \the [src] with \the [weapon]."))
				if(weapon.contents.len)
					to_chat(user, span_warning("Some items are refused."))
				if (visible_contents)
					update_appearance()
				return TRUE
			else
				to_chat(user, span_warning("There is nothing in [weapon] to put in [src]!"))
				return FALSE

	if(!user.combat_mode)
		to_chat(user, span_warning("\The [src] smartly refuses [weapon]."))
		return FALSE

	else
		return ..()

/**
 * Can this item be accepted by the smart fridge
 * Arguments
 * * [weapon][obj/item] - the item to accept
 */
/obj/machinery/smartfridge/proc/accept_check(obj/item/weapon)
	var/static/list/accepted_items = list(
		/obj/item/food/grown,
		/obj/item/seeds,
		/obj/item/grown,
		/obj/item/graft,
	)
	return is_type_in_list(weapon, accepted_items)

/**
 * Loads the item into the smart fridge
 * Arguments
 * * [weapon][obj/item] - the item to load. If the item is being held by a mo it will transfer it from hand else directly force move
 */
/obj/machinery/smartfridge/proc/load(obj/item/weapon)
	if(ismob(weapon.loc))
		var/mob/owner = weapon.loc
		if(!owner.transferItemToLoc(weapon, src))
			to_chat(usr, span_warning("\the [weapon] is stuck to your hand, you cannot put it in \the [src]!"))
			return FALSE
		return TRUE
	else
		if(weapon.loc.atom_storage)
			return weapon.loc.atom_storage.attempt_remove(weapon, src, silent = TRUE)
		else
			weapon.forceMove(src)
			return TRUE

/obj/machinery/smartfridge/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "SmartVend", name)
		ui.set_autoupdate(FALSE)
		ui.open()

/obj/machinery/smartfridge/ui_data(mob/user)
	. = list()

	var/listofitems = list()
	for (var/item in src)
		// We do not vend our own components.
		if(item in component_parts)
			continue

		var/atom/movable/atom = item
		if (!QDELETED(atom))
			var/md5name = md5(atom.name) // This needs to happen because of a bug in a TGUI component, https://github.com/ractivejs/ractive/issues/744
			if (listofitems[md5name]) // which is fixed in a version we cannot use due to ie8 incompatibility
				listofitems[md5name]["amount"]++ // The good news is, #30519 made smartfridge UIs non-auto-updating
			else
				listofitems[md5name] = list("name" = atom.name, "amount" = 1)
	sort_list(listofitems)

	.["contents"] = listofitems
	.["name"] = name
	.["isdryer"] = FALSE

/obj/machinery/smartfridge/Exited(atom/movable/gone, direction) // Update the UIs in case something inside is removed
	. = ..()
	SStgui.update_uis(src)

/obj/machinery/smartfridge/ui_act(action, params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(. || !ui.user.can_perform_action(src, FORBID_TELEKINESIS_REACH))
		return

	. = TRUE
	var/mob/living_mob = ui.user

	switch(action)
		if("Release")
			var/desired = 0

			if(isAI(living_mob))
				to_chat(living_mob, span_warning("[src] does not respect your authority!"))
				return

			if (params["amount"])
				desired = text2num(params["amount"])
			else
				desired = tgui_input_number(living_mob, "How many items would you like to take out?", "Release", max_value = 50)
				if(!desired)
					return

			for(var/obj/item/dispensed_item in src)
				if(desired <= 0)
					break
				// Grab the first item in contents which name matches our passed name.
				// format_text() is used here to strip \improper and \proper from both names,
				// which is required for correct string comparison between them.
				if(format_text(dispensed_item.name) == format_text(params["name"]))
					if(dispensed_item in component_parts)
						CRASH("Attempted removal of [dispensed_item] component_part from smartfridge via smartfridge interface.")
					//dispense the item
					if(!living_mob.put_in_hands(dispensed_item))
						dispensed_item.forceMove(drop_location())
						adjust_item_drop_location(dispensed_item)
					use_power(active_power_usage)
					desired--

			if (visible_contents)
				update_appearance()
			return

	return FALSE

// ----------------------------
//  Drying Rack 'smartfridge'
// ----------------------------
/obj/machinery/smartfridge/drying_rack
	name = "drying rack"
	desc = "A wooden contraption, used to dry plant products, food and hide."
	icon = 'icons/obj/service/hydroponics/equipment.dmi'
	icon_state = "drying_rack"
	resistance_flags = FLAMMABLE
	visible_contents = FALSE
	base_build_path = /obj/machinery/smartfridge/drying_rack //should really be seeing this without admin fuckery.
	use_power = NO_POWER_USE
	idle_power_usage = 0
	has_emissive = FALSE
	can_atmos_pass = ATMOS_PASS_YES
	/// Is the rack currently drying stuff
	var/drying = FALSE

/obj/machinery/smartfridge/drying_rack/Initialize(mapload)
	. = ..()

	//you can't weld down wood
	welded_down = FALSE

	//so we don't drop any of the parent smart fridge parts upon deconstruction
	clear_components()

/// We cleared out the components in initialize so we can optimize this
/obj/machinery/smartfridge/drying_rack/visible_items()
	return contents.len

/obj/machinery/smartfridge/drying_rack/add_context(atom/source, list/context, obj/item/held_item, mob/living/user)
	if(isnull(held_item))
		return NONE

	var/tool_tip_set = FALSE
	if(held_item.tool_behaviour == TOOL_CROWBAR)
		context[SCREENTIP_CONTEXT_LMB] = "Deconstruct"
		tool_tip_set = TRUE
	else if(held_item.tool_behaviour == TOOL_WRENCH)
		context[SCREENTIP_CONTEXT_LMB] = "[anchored ? "Un" : ""]anchore"
		tool_tip_set = TRUE

	return tool_tip_set ? CONTEXTUAL_SCREENTIP_SET : NONE

/obj/machinery/smartfridge/drying_rack/structure_examine()
	. = ""
	if(anchored)
		. += span_info("It's currently anchored to the floor. It can be [EXAMINE_HINT("wrenched")] loose.")
	else
		. += span_info("It's not anchored to the floor. It can be [EXAMINE_HINT("wrenched")] down.")
	. += span_info("The whole rack can be [EXAMINE_HINT("pried")] apart.")

/obj/machinery/smartfridge/drying_rack/welder_act(mob/living/user, obj/item/tool)
	return NONE

/obj/machinery/smartfridge/drying_rack/welder_act_secondary(mob/living/user, obj/item/tool)
	return NONE

/obj/machinery/smartfridge/drying_rack/default_deconstruction_screwdriver()
	return NONE

/obj/machinery/smartfridge/drying_rack/exchange_parts()
	return

/obj/machinery/smartfridge/drying_rack/on_deconstruction()
	new /obj/item/stack/sheet/mineral/wood(drop_location(), 10)

/obj/machinery/smartfridge/drying_rack/crowbar_act(mob/living/user, obj/item/tool)
	if(default_deconstruction_crowbar(tool, ignore_panel = TRUE))
		return ITEM_INTERACT_SUCCESS

/obj/machinery/smartfridge/drying_rack/ui_data(mob/user)
	. = ..()
	.["isdryer"] = TRUE
	.["drying"] = drying

/obj/machinery/smartfridge/drying_rack/ui_act(action, params)
	. = ..()
	if(.)
		update_appearance() // This is to handle a case where the last item is taken out manually instead of through drying pop-out
		return

	switch(action)
		if("Dry")
			toggle_drying(FALSE)
			return TRUE

/obj/machinery/smartfridge/drying_rack/powered()
	return !anchored ? FALSE : ..()

/obj/machinery/smartfridge/drying_rack/power_change()
	. = ..()
	if(!powered())
		toggle_drying(TRUE)

/obj/machinery/smartfridge/drying_rack/load(obj/item/dried_object) //For updating the filled overlay
	. = ..()
	update_appearance()

/obj/machinery/smartfridge/drying_rack/update_overlays()
	. = ..()
	if(drying)
		. += "drying_rack_drying"
	if(contents.len)
		. += "drying_rack_filled"

/obj/machinery/smartfridge/drying_rack/process()
	if(drying)
		for(var/obj/item/item_iterator in src)
			if(!accept_check(item_iterator))
				continue
			rack_dry(item_iterator)

		SStgui.update_uis(src)
		update_appearance()
		use_power(active_power_usage)

/obj/machinery/smartfridge/drying_rack/accept_check(obj/item/O)
	return HAS_TRAIT(O, TRAIT_DRYABLE)

/**
 * Toggles drying on or off
 * Arguments
 * * forceoff - if TRUE will force the dryer off always
 */
/obj/machinery/smartfridge/drying_rack/proc/toggle_drying(forceoff)
	if(drying || forceoff)
		drying = FALSE
		update_use_power(IDLE_POWER_USE)
	else
		drying = TRUE
		update_use_power(ACTIVE_POWER_USE)
	update_appearance()

/obj/machinery/smartfridge/drying_rack/proc/rack_dry(obj/item/target)
	SEND_SIGNAL(target, COMSIG_ITEM_DRIED)

/obj/machinery/smartfridge/drying_rack/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	atmos_spawn_air("[TURF_TEMPERATURE(1000)]")

// ----------------------------
//  Bar drink smartfridge
// ----------------------------
/obj/machinery/smartfridge/drinks
	name = "drink showcase"
	desc = "A refrigerated storage unit for tasty tasty alcohol."
	base_build_path = /obj/machinery/smartfridge/drinks
	contents_icon_state = "drink"

/obj/machinery/smartfridge/drinks/accept_check(obj/item/weapon)
	//not an item or valid container
	if(!is_reagent_container(weapon))
		return FALSE

	//an bowl or something that has no reagents
	if(istype(weapon,/obj/item/reagent_containers/cup/bowl) || !length(weapon.reagents?.reagent_list))
		return FALSE

	//list of items acceptable
	return (istype(weapon, /obj/item/reagent_containers/cup) || istype(weapon, /obj/item/reagent_containers/condiment))

// ----------------------------
//  Food smartfridge
// ----------------------------
/obj/machinery/smartfridge/food
	desc = "A refrigerated storage unit for food."
	base_build_path = /obj/machinery/smartfridge/food
	contents_icon_state = "food"

/obj/machinery/smartfridge/food/accept_check(obj/item/weapon)
	if(weapon.w_class >= WEIGHT_CLASS_BULKY)
		return FALSE
	if(IS_EDIBLE(weapon))
		return TRUE
	if(istype(weapon, /obj/item/reagent_containers/cup/bowl) && weapon.reagents?.total_volume > 0)
		return TRUE
	return FALSE

// -------------------------------------
// Xenobiology Slime-Extract Smartfridge
// -------------------------------------
/obj/machinery/smartfridge/extract
	name = "smart slime extract storage"
	desc = "A refrigerated storage unit for slime extracts."
	base_build_path = /obj/machinery/smartfridge/extract
	contents_icon_state = "slime"

/obj/machinery/smartfridge/extract/accept_check(obj/item/weapon)
	return (istype(weapon, /obj/item/slime_extract) || istype(weapon, /obj/item/slime_scanner))

/obj/machinery/smartfridge/extract/preloaded
	initial_contents = list(/obj/item/slime_scanner = 2)

// -------------------------------------
// Cytology Petri Dish Smartfridge
// -------------------------------------
/obj/machinery/smartfridge/petri
	name = "smart petri dish storage"
	desc = "A refrigerated storage unit for petri dishes."
	base_build_path = /obj/machinery/smartfridge/petri
	contents_icon_state = "petri"

/obj/machinery/smartfridge/petri/accept_check(obj/item/weapon)
	return istype(weapon, /obj/item/petri_dish)

/obj/machinery/smartfridge/petri/preloaded
	initial_contents = list(/obj/item/petri_dish = 5)

// -------------------------
// Organ Surgery Smartfridge
// -------------------------
/obj/machinery/smartfridge/organ
	name = "smart organ storage"
	desc = "A refrigerated storage unit for organ storage."
	max_n_of_items = 20 //vastly lower to prevent processing too long
	base_build_path = /obj/machinery/smartfridge/organ
	contents_icon_state = "organ"
	/// The rate at which this fridge will repair damaged organs
	var/repair_rate = 0

/obj/machinery/smartfridge/organ/accept_check(obj/item/O)
	return (isorgan(O) || isbodypart(O))

/obj/machinery/smartfridge/organ/load(obj/item/O)
	. = ..()
	if(!.) //if the item loads, clear can_decompose
		return

	if(isorgan(O))
		var/obj/item/organ/organ = O
		organ.organ_flags |= ORGAN_FROZEN

	if(isbodypart(O))
		var/obj/item/bodypart/bodypart = O
		for(var/obj/item/organ/stored in bodypart.contents)
			stored.organ_flags |= ORGAN_FROZEN

/obj/machinery/smartfridge/organ/RefreshParts()
	. = ..()
	for(var/datum/stock_part/matter_bin/matter_bin in component_parts)
		max_n_of_items = 20 * matter_bin.tier
		repair_rate = max(0, STANDARD_ORGAN_HEALING * (matter_bin.tier - 1) * 0.5)

/obj/machinery/smartfridge/organ/process(seconds_per_tick)
	for(var/obj/item/organ/target_organ in contents)
		if(!target_organ.damage)
			continue

		target_organ.apply_organ_damage(-repair_rate * target_organ.maxHealth * seconds_per_tick, required_organ_flag = ORGAN_ORGANIC)

/obj/machinery/smartfridge/organ/Exited(atom/movable/gone, direction)
	. = ..()

	if(isorgan(gone))
		var/obj/item/organ/O = gone
		O.organ_flags &= ~ORGAN_FROZEN

	if(isbodypart(gone))
		var/obj/item/bodypart/bodypart = gone
		for(var/obj/item/organ/stored in bodypart.contents)
			stored.organ_flags &= ~ORGAN_FROZEN

// -----------------------------
// Chemistry Medical Smartfridge
// -----------------------------
/obj/machinery/smartfridge/chemistry
	name = "smart chemical storage"
	desc = "A refrigerated storage unit for medicine storage."
	base_build_path = /obj/machinery/smartfridge/chemistry
	contents_icon_state = "chem"

/obj/machinery/smartfridge/chemistry/accept_check(obj/item/weapon)
	// not an item or reagent container
	if(!is_reagent_container(weapon))
		return FALSE

	// empty pill prank ok
	if(istype(weapon, /obj/item/reagent_containers/pill))
		return TRUE

	//check each pill in the pill bottle
	if(istype(weapon, /obj/item/storage/pill_bottle))
		if(weapon.contents.len)
			for(var/obj/item/target_item in weapon)
				if(!accept_check(target_item))
					return FALSE
			return TRUE
		return FALSE

	// other empty containers not accepted
	if(!length(weapon.reagents?.reagent_list))
		return FALSE

	// the long list of other containers that can be accepted
	var/static/list/chemfridge_typecache = typecacheof(list(
					/obj/item/reagent_containers/syringe,
					/obj/item/reagent_containers/cup/tube,
					/obj/item/reagent_containers/cup/bottle,
					/obj/item/reagent_containers/cup/beaker,
					/obj/item/reagent_containers/spray,
					/obj/item/reagent_containers/medigel,
					/obj/item/reagent_containers/cup/hypovial, // EffigyEdit Add (Medical)
					/obj/item/reagent_containers/chem_pack
	))
	return is_type_in_typecache(weapon, chemfridge_typecache)

/obj/machinery/smartfridge/chemistry/preloaded
	initial_contents = list(
		/obj/item/reagent_containers/pill/epinephrine = 12,
		/obj/item/reagent_containers/pill/multiver = 5,
		/obj/item/reagent_containers/cup/bottle/epinephrine = 1,
		/obj/item/reagent_containers/cup/bottle/multiver = 1)

// ----------------------------
// Virology Medical Smartfridge
// ----------------------------
/obj/machinery/smartfridge/chemistry/virology
	name = "smart virus storage"
	desc = "A refrigerated storage unit for volatile sample storage."
	base_build_path = /obj/machinery/smartfridge/chemistry/virology
	contents_icon_state = "viro"

/obj/machinery/smartfridge/chemistry/virology/preloaded
	initial_contents = list(
		/obj/item/storage/pill_bottle/sansufentanyl = 2,
		/obj/item/reagent_containers/syringe/antiviral = 4,
		/obj/item/reagent_containers/cup/bottle/cold = 1,
		/obj/item/reagent_containers/cup/bottle/flu_virion = 1,
		/obj/item/reagent_containers/cup/bottle/mutagen = 1,
		/obj/item/reagent_containers/cup/bottle/sugar = 1,
		/obj/item/reagent_containers/cup/bottle/plasma = 1,
		/obj/item/reagent_containers/cup/bottle/synaptizine = 1,
		/obj/item/reagent_containers/cup/bottle/formaldehyde = 1)

// ----------------------------
// Disk """fridge"""
// ----------------------------
/obj/machinery/smartfridge/disks
	name = "disk compartmentalizer"
	desc = "A machine capable of storing a variety of disks. Denoted by most as the DSU (disk storage unit)."
	icon_state = "disktoaster"
	icon = 'icons/obj/machines/vending.dmi'
	pass_flags = PASSTABLE
	can_atmos_pass = ATMOS_PASS_YES
	visible_contents = FALSE
	base_build_path = /obj/machinery/smartfridge/disks

/obj/machinery/smartfridge/disks/accept_check(obj/item/weapon)
	return istype(weapon, /obj/item/disk)
