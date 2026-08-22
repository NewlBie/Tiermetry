import os
files = [
    '018.png', '8ball.png', 'airsofetgun.png', 'archer.png', 'atv.png', 'axe.png', 'badminton.png', 'bowling.png', 'bungee.png', 'camp.png', 'cricket.png', 'dance.png', 'go_kart.png', 'horse.png', 'ice_skate.png', 'indoor_mountain_climb.png', 'jet_ski.png', 'kayak.png', 'laser.png', 'offroad.png', 'padel.png', 'paint.png', 'paintball.png', 'paraglide.png', 'parasail.png', 'pc.png', 'pickel.png', 'pottery.png', 'ps5.png', 'race_sim.png', 'river_raft.png', 'roller.png', 'roller_skate.png', 'scuba.png', 'sky_diving.png', 'surf.png', 'swimming.png', 'trampoline.png', 'treck.png', 'vr.png', 'water_park.png', 'zipline.png'
]

groups = {
    'Gaming & E-Sports': ['pc', 'ps5', 'race_sim', 'vr'],
    'Adventures & Water': ['bungee', 'camp', 'jet_ski', 'kayak', 'paraglide', 'parasail', 'river_raft', 'scuba', 'sky_diving', 'surf', 'swimming', 'treck', 'water_park', 'zipline'],
    'Action & Motor': ['airsofetgun', 'archer', 'atv', 'axe', 'go_kart', 'indoor_mountain_climb', 'laser', 'offroad', 'paint', 'paintball'],
    'Sports & Leisure': ['018', '8ball', 'badminton', 'bowling', 'cricket', 'dance', 'horse', 'ice_skate', 'padel', 'pickel', 'pottery', 'roller', 'roller_skate', 'trampoline']
}

out = '    devices: [\n'
cat_id = 1
unit_id = 1
for cat_name, items in groups.items():
    out += f"      ArenaDeviceCatModel(\n"
    out += f"        id: 'cat-{cat_id}',\n"
    out += f"        name: '{cat_name}',\n"
    out += f"        units: [\n"
    
    for item in items:
        name = item.replace('_', ' ').title()
        if name == '018': name = 'Football Turf'
        is_occ = (unit_id % 3 == 0)
        
        out += f"          ArenaDeviceModel(\n"
        out += f"            id: 'unit-{unit_id}',\n"
        out += f"            name: '{name}',\n"
        out += f"            desc: '{'In use' if is_occ else 'Available'}',\n"
        out += f"            price: 500,\n"
        out += f"            image: 'assets/act_imgs/{item}.png',\n"
        out += f"            isOccupied: {'true' if is_occ else 'false'},\n"
        if is_occ:
            out += f"            occupiedTill: now.add(const Duration(hours: 1)),\n"
        
        out += f"          ),\n"
        unit_id += 1
    out += '        ],\n      ),\n'
    cat_id += 1
out += '    ],'

with open('devices_block.txt', 'w') as f:
    f.write(out)
print('Done')
