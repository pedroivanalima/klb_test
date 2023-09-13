class Reader
    MARKER = /-{60}/

    def initialize(logfile_path)
        @log = logfile_path
    end

    # we read match by match so we don't keep the whole log on memory
    def read_match
        resp = []
        while !file.eof?
            line = file.readline
            # not all logs starts and ends with ---- so we may not have a starting line (or an ending line)
            if line.match? MARKER
                next if resp.empty?
                break
            end
            resp << line
        end
        return false if resp.empty?
        resp
    end

    private
    def file
        @file ||= File.open(@log)
    end
end

class Match
    
    DEATH_CAUSES = %i[MOD_UNKNOWN MOD_SHOTGUN MOD_GAUNTLET MOD_MACHINEGUN MOD_GRENADE MOD_GRENADE_SPLASH MOD_ROCKET MOD_ROCKET_SPLASH MOD_PLASMA MOD_PLASMA_SPLASH MOD_RAILGUN MOD_LIGHTNING MOD_BFG MOD_BFG_SPLASH MOD_WATER MOD_SLIME MOD_LAVA MOD_CRUSH MOD_TELEFRAG MOD_FALLING MOD_SUICIDE MOD_TARGET_LASER MOD_TRIGGER_HURT MOD_NAIL MOD_CHAINGUN MOD_PROXIMITY_MINE MOD_KAMIKAZE MOD_JUICED MOD_GRAPPLE]
    WORLD_ID = 1022

    def initialize(match_lines, match_number, death_log = false)
        @match_lines = match_lines
        @match_number = match_number
        @total_kills = 0
        @players = {}
        # we are reversing here so when ordering by value and reverting it reverts back to original order 
        @kills = {} ; DEATH_CAUSES.reverse.map{ |dc| @kills[dc] = 0 } 
        @death_log = death_log
    end

    def perform()       
        begin 
            @match_lines.each do |line|
                hour, action, other = line.scan(/(\d+:\d+)\s(\w+):\s(.*)$/).first
                case action
                when "ClientUserinfoChanged"
                    update_client_info(other)
                when "Kill"
                    update_kill(other)
                end
            end

            decorate_response
        rescue StandardError => e
            # keep track of the error and not break the whole parsing
            return e.message
        end
    end

    def death_log()
        return nil unless @death_log

        { match_name => { "kills_by_means" => @kills.sort_by{ |_key, value| value }.reverse.to_h } }
    end

    private 

    def update_client_info(info)
        client_id, client_name = info.scan(/(\d+)\sn\\([^\\]+)\\t/).first

        if @players[client_id].nil?
            @players[client_id] = { name: client_name, kills: 0 }
        else
            @players[client_id][:name] = client_name
        end
    end

    # F
    def update_kill(info)
        killer_id, killed_id, death_cause_id = info.scan(/(\d+)\s(\d+)\s(\d+):.*/).first
        @total_kills += 1
        if killer_id.to_i == WORLD_ID || killer_id == killed_id
            # let that be negative, shame on them... in any case max(result, 0) would do the trick
            @players[killed_id][:kills] -= 1
        else
            @players[killer_id][:kills] += 1
        end
        
        @kills[death_cause(death_cause_id)] += 1 if @death_log
    end

    def decorate_response()
        resp = {
            match_name => { 
                "total_kills" => @total_kills,
                "players" => [],
                "kills" => {},
            }
        }

        @players.each do |_player_id, info|
            resp[match_name]["players"] << info[:name]
            resp[match_name]["kills"][info[:name]] = info[:kills]
        end

        resp
    end

    def match_name
        "Game_#{@match_number}"
    end

    def death_cause(id)
        DEATH_CAUSES[id.to_i]
    end
end

# are we creating the deathlog?
death_log = ARGV[0].downcase == "deathlog"

# instantiate the reading of the whole file
reader = Reader.new("entry.log")

# and read on by one until reader cannot read anymore
count = 1
match_read = reader.read_match
while match_read != false and count <= 30   
    match = Match.new(match_read, count, death_log)
    match_result = match.perform 
    puts match_result
    puts match.death_log if death_log
    count += 1
    match_read = reader.read_match
end