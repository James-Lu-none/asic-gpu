# Visualization only. Boxes enclose name-matched placed instances, not regions.
# Flattened/anonymous cells are left gray; no ownership is inferred from wiring.
namespace eval module_view {}

proc module_view::save {} {
  set block [ord::get_db_block]
  set image_prefix final
  if {[info exists ::env(IMAGE_PREFIX)]} { set image_prefix $::env(IMAGE_PREFIX) }
  set groups [dict create]
  set total 0
  foreach inst [$block getInsts] {
    if {![$inst isPlaced] || [$inst isPhysicalOnly] || \
        [[$inst getMaster] getType] in {CORE_SPACER CORE_WELLTAP}} { continue }
    incr total
    set name [$inst getName]
    set path [string map {\\ {}} $name]
    set group ""
    if {[regexp {^(.*?gen_sub_partitions\[[0-9]+\]\.u_sp)(\.|$)} $path -> prefix]} {
      set group $prefix
    } elseif {[regexp {^(u_sp)(\.|$)} $path -> prefix]} {
      set group $prefix
    } elseif {[regexp {^(.*?u_l[12]_cache)(\.|$)} $path -> prefix]} {
      set group $prefix
    }
    if {$group ne ""} { dict lappend groups $group $inst }
  }

  gui::save_display_controls
  gui::clear_highlights -1
  gui::clear_selections
  gui::set_display_controls "*" visible false
  foreach control {Layers/* Instances/* Shape\ Types/*} {
    gui::set_display_controls $control visible true
  }
  gui::set_display_controls "Shape Types/Routing/*" visible false
  gui::set_display_controls "Instances/Physical/*" visible false
  gui::set_display_controls "Misc/Scale bar" visible true
  gui::set_display_controls "Misc/Detailed view" visible true
  gui::set_display_controls "Misc/Highlight selected" visible true
  gui::set_display_controls "Rulers" visible true
  gui::set_display_controls "Misc/Labels" visible true
  gui::fit

  set report [open $::env(REPORTS_DIR)/module_view.tsv w]
  puts $report "# Name-matched instances only; boxes may overlap and are not floorplan constraints."
  set core [$block getCoreArea]
  puts $report "# core_width_um=[ord::dbu_to_microns [$core dx]] core_height_um=[ord::dbu_to_microns [$core dy]]"
  puts $report "group\tinstances\tmacros\txmin_um\tymin_um\txmax_um\tymax_um"
  set palette {green yellow cyan magenta red dark_green dark_magenta blue}
  set index 0
  set matched 0
  set rulers {}
  set labels {}
  set die [$block getDieArea]
  set dy [expr {max(1, [$die dy] / 45)}]
  foreach group [lsort -dictionary [dict keys $groups]] {
    set color_index [expr {$index % 8}]
    set color [lindex $palette $color_index]
    set xmin 1e30; set ymin 1e30; set xmax -1e30; set ymax -1e30
    set macros 0
    foreach inst [dict get $groups $group] {
      set box [$inst getBBox]
      set xmin [expr {min($xmin, [$box xMin])}]
      set ymin [expr {min($ymin, [$box yMin])}]
      set xmax [expr {max($xmax, [$box xMax])}]
      set ymax [expr {max($ymax, [$box yMax])}]
      if {[[$inst getMaster] isBlock]} { incr macros }
      gui::highlight_inst [$inst getName] $color_index
      incr matched
    }
    foreach coord {xmin ymin xmax ymax} {
      set $coord [ord::dbu_to_microns [set $coord]]
    }
    set count [llength [dict get $groups $group]]
    puts $report "$group\t$count\t$macros\t$xmin\t$ymin\t$xmax\t$ymax"

    # Highlight rulers as lines to give the visual box the same group color.
    set edge 0
    foreach coords [list [list $xmin $ymin $xmax $ymin] \
                         [list $xmax $ymin $xmax $ymax] \
                         [list $xmax $ymax $xmin $ymax] \
                         [list $xmin $ymax $xmin $ymin]] {
      set ruler [gui::add_ruler {*}$coords "" module_view_${index}_${edge} 1]
      lappend rulers $ruler
      select -type Ruler -name ^${ruler}$ -highlight $color_index
      incr edge
    }
    # Separate legend rows keep names readable even when boxes overlap.
    set x [ord::dbu_to_microns [$die xMin]]
    set y [ord::dbu_to_microns [expr {[$die yMax] - ($index + 1) * $dy}]]
    set title $group
    regsub {^u_sp$} $title {SP0} title
    regsub {gen_sub_partitions\[([0-9]+)\]\.u_sp$} $title {SP\1} title
    regsub {gen_sm_array\[([0-9]+)\]\.u_sm\.} $title {SM\1/} title
    regsub {u_l([12])_cache$} $title {L\1} title
    lappend labels [add_label -position [list $x $y] -anchor "left center" \
      -color $color -size 14 $title]
    incr index
  }
  puts $report "# matched=$matched total_nonphysical_placed=$total unmatched=[expr {$total - $matched}]"
  close $report
  if {$matched == 0} {
    puts "WARNING: Module view found no SP/cache instance paths; see module_view.tsv."
  }
  set resolution [expr {[ord::dbu_to_microns [$die dy]] / 1600.0}]
  # Keep the overview readable; overlapping bounds have their own image.
  gui::set_display_controls "Rulers" visible false
  gui::clear_selections
  save_image -resolution $resolution $::env(REPORTS_DIR)/${image_prefix}_modules.webp
  gui::set_display_controls "Rulers" visible true
  save_image -resolution $resolution $::env(REPORTS_DIR)/${image_prefix}_module_bounds.webp
  foreach ruler $rulers { gui::delete_ruler $ruler }
  foreach label $labels { gui::delete_label $label }
  gui::clear_highlights -1
  gui::clear_selections
  gui::restore_display_controls
}

if {[ord::get_db_block] eq "NULL"} {
  if {[info exists ::env(IMAGE_DB)]} {
    read_db $::env(IMAGE_DB)
  } else {
    read_db $::env(RESULTS_DIR)/6_final.odb
  }
}
gui::show {module_view::save} false
