#!/usr/bin/env tclsh

package require http
package require json
package require Tk

wm title . "TraceRoute GeoLocation Utility"
wm geometry . "1200x600"
wm minsize . 900 600

# define initial variables
set traceroute_bin "/usr/bin/traceroute"
set gnuplot_bin "/usr/bin/gnuplot"
set world_map_data "/usr/share/doc/gnuplot-doc/demo/world.dat"
set traceroute_geolocation_gnuplot "traceroute-geolocation.gnuplot"

# entry insert proc
proc entry_insert {entry_name value color} {
    $entry_name configure -state normal
    $entry_name delete 0 end
    $entry_name insert end $value
    $entry_name configure -state readonly -readonlybackground $color
}

# return an dict of IP details
proc get_ip_info_dict {ip_address} {
    set ip_dict {}

    set ip_info_url "http://ipwhois.app/json/"
    set ip_request_url [string cat $ip_info_url $ip_address]

    set http_request_handle [::http::geturl $ip_request_url]

    if {[string equal [::http::status $http_request_handle] "ok"] == 1} {
        set ip_info_response_dict [::json::json2dict [::http::data $http_request_handle]]

        set ip_query_status [dict get $ip_info_response_dict success]
        if {[string equal $ip_query_status "true"] == 1} {
            set ip_dict $ip_info_response_dict
        }
    }

    return $ip_dict
}

# return a list of IP addresses from traceroute result
proc get_traceroute_ip_addresses {ip_address} {
    set traceroute_ip_list {}

    if {[catch {exec $::traceroute_bin $ip_address -n -q1} traceroute_result] == 0} {
        # skip traceroute result header by using lrange
        foreach result_entry [lrange [split $traceroute_result "\n"] 1 end] {
            lappend traceroute_ip_list [lindex $result_entry 1]
        }
    } else {
        puts $traceroute_result
    }

    return $traceroute_ip_list
}

# display traceroute result
proc display_traceroute_result {} { 
    # get input IP address
    set ip_address [.ip_input get]

    # destroy children of .traceroute_data widget
    foreach widget_name [winfo children .traceroute_data] {
        destroy $widget_name
    }

    # process IP address
    if {[string equal ip_address ""] == 0} {
        # create gnuplot data file
        global env
        set timestamp [clock seconds]
        set gnuplot_file_name [string cat $ip_address "_" $timestamp ".gnuplot"]
        set gnuplot_file [open [file join $env(HOME) $gnuplot_file_name] w]

        # get traceroute result
        set traceroute_ip_list [get_traceroute_ip_addresses $ip_address]

        if {[llength $traceroute_ip_list] > 0} {
            # set up header
            set header {.traceroute_data.ip "IP" .traceroute_data.continent "Continent" .traceroute_data.country "Country" .traceroute_data.region "Region" .traceroute_data.city "City" .traceroute_data.latitude "Latitude" .traceroute_data.longitude "Longitude" .traceroute_data.isp "ISP"}

            dict for {widget_name widget_text} $header {
                label $widget_name -text $widget_text -justify center
            }

            grid .traceroute_data.ip .traceroute_data.continent .traceroute_data.country .traceroute_data.region .traceroute_data.city .traceroute_data.latitude .traceroute_data.longitude .traceroute_data.isp -sticky nsew

            set e 0

            foreach ip $traceroute_ip_list {
                # set up entry widget
                entry .traceroute_data.entry_ip_$e -state readonly -width 32 -justify center
                entry .traceroute_data.entry_continent_$e -state readonly -width 12 -justify center
                entry .traceroute_data.entry_country_$e -state readonly -width 32 -justify center
                entry .traceroute_data.entry_region_$e -state readonly -width 32 -justify center
                entry .traceroute_data.entry_city_$e -state readonly -width 32 -justify center
                entry .traceroute_data.entry_latitude_$e -state readonly -width 12 -justify center
                entry .traceroute_data.entry_longitude_$e -state readonly -width 12 -justify center
                entry .traceroute_data.entry_isp_$e -state readonly -width 64 -justify center

                grid .traceroute_data.entry_ip_$e .traceroute_data.entry_continent_$e .traceroute_data.entry_country_$e .traceroute_data.entry_region_$e .traceroute_data.entry_city_$e .traceroute_data.entry_latitude_$e .traceroute_data.entry_longitude_$e .traceroute_data.entry_isp_$e -sticky nsew

                if {[string equal $ip "*"] == 0} {
                    # retrieve IP info
                    set ip_info [get_ip_info_dict $ip]

                    if {[dict size $ip_info] > 0} {
                        entry_insert .traceroute_data.entry_ip_$e [dict get $ip_info "ip"] "light green"
                        entry_insert .traceroute_data.entry_continent_$e [dict get $ip_info "continent"] "light green"
                        entry_insert .traceroute_data.entry_country_$e [dict get $ip_info "country"] "light green"
                        entry_insert .traceroute_data.entry_region_$e [dict get $ip_info "region"] "light green"
                        entry_insert .traceroute_data.entry_city_$e [dict get $ip_info "city"] "light green"
                        entry_insert .traceroute_data.entry_latitude_$e [dict get $ip_info "latitude"] "light green"
                        entry_insert .traceroute_data.entry_longitude_$e [dict get $ip_info "longitude"] "light green"
                        entry_insert .traceroute_data.entry_isp_$e [dict get $ip_info "isp"] "light green"

                        # write data points to gnuplot file
                        # format: <longitude> <latitude> <city_name>
                        set gnuplot_entry [string cat [dict get $ip_info "longitude"] " " [dict get $ip_info "latitude"] " " \"[dict get $ip_info "city"]\"]
                        puts $gnuplot_file $gnuplot_entry
                    } else {
                        entry_insert .traceroute_data.entry_ip_$e "API ERROR" "red"
                        entry_insert .traceroute_data.entry_continent_$e "API ERROR" "red"
                        entry_insert .traceroute_data.entry_country_$e "API ERROR" "red"
                        entry_insert .traceroute_data.entry_region_$e "API ERROR" "red"
                        entry_insert .traceroute_data.entry_city_$e "API ERROR" "red"
                        entry_insert .traceroute_data.entry_latitude_$e "API ERROR" "red"
                        entry_insert .traceroute_data.entry_longitude_$e "API ERROR" "red"
                        entry_insert .traceroute_data.entry_isp_$e "API ERROR" "red"
                    }
                } else {
                    entry_insert .traceroute_data.entry_ip_$e "TIMEOUT" "yellow"
                    entry_insert .traceroute_data.entry_continent_$e "TIMEOUT" "yellow"
                    entry_insert .traceroute_data.entry_country_$e "TIMEOUT" "yellow"
                    entry_insert .traceroute_data.entry_region_$e "TIMEOUT" "yellow"
                    entry_insert .traceroute_data.entry_city_$e "TIMEOUT" "yellow"
                    entry_insert .traceroute_data.entry_latitude_$e "TIMEOUT" "yellow"
                    entry_insert .traceroute_data.entry_longitude_$e "TIMEOUT" "yellow"
                    entry_insert .traceroute_data.entry_isp_$e "TIMEOUT" "yellow"
                }

                incr e 1
            }

        close $gnuplot_file

        # create geolocation graph
        # ARG0: gnuplot script
        # ARG1: world map data
        # ARG2: traceroute geolocation data
        # ARG3: prefix name of output pictures
        # ARG4: destination IP in title
        if {[catch {exec $::gnuplot_bin -c $::traceroute_geolocation_gnuplot $::world_map_data [file join $env(HOME) $gnuplot_file_name] [file join $env(HOME) [string cat $ip_address "_" $timestamp]] $ip_address} output] == 0} {
        } else {
            # pop up a window if gnuplot is failed
            tk_messageBox -message "Failed to execute gnuplot command: $output" -icon error
        }
        } else {
            # pop up a window if traceroute is failed
            tk_messageBox -message "Failed to execute traceroute command!" -icon error
        }
    }
}

# main UI

label .ip_address -text "IP ADDRESS" -justify left
entry .ip_input -width 128 -justify right

labelframe .traceroute_data -text "TRACEROUTE IP INFORMATION" -labelanchor n

button .go -text "GO" -background green -justify center -command display_traceroute_result
button .exit -text "EXIT" -background red -justify center -command exit

# widgets layout
grid .ip_address -row 0 -column 0 -sticky w
grid .ip_input -row 0 -column 1 -sticky e
grid .traceroute_data -row 1 -column 0 -sticky nsew -columnspan 2 
grid .go -row 3 -column 0 -sticky sew -columnspan 2
grid .exit -row 4 -column 0 -sticky sew -columnspan 2

grid rowconfigure . 1 -weight 1
grid columnconfigure . 0 -weight 1
grid columnconfigure . 1 -weight 1
