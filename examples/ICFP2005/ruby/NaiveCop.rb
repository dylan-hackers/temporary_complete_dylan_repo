def brain_pick_initial_transport()
    'cop-car'.intern
end

def brain_pick_next_location()
    locations = reachable_locations($current_location, $transport)
    locations = locations.collect do |location|
        node_for_location(location)
    end
    locations[rand(locations.size)].name
end
