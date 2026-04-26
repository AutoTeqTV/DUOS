-- DUOS FlightHUD v0.3 visual identity pass
-- Based on ArchHUD; core behavior preserved for compatibility.
function programClass(Nav, c, u, atlas, vBooster, hover, telemeter_1, antigrav, dbHud_1, dbHud_2, radar_1, radar_2, shield, gyro, warpdrive, weapon, screenHud_1, transponder)
    local s = DUSystem
    local C = DUConstruct
    local P = DUPlayer
    local library = DULibrary
    -- Local variables and functions
        local program = {}

        local stringf = string.format
        local jdecode = json.decode
        local jencode = json.encode
        local eleMaxHp = c.getElementMaxHitPointsById
        local eleMass = c.getElementMassById
		local isRemote = Nav.control.isRemoteControlled
        local stringmatch = string.match
        local sysDestWid = s.destroyWidgetPanel
        local sysUpData = s.updateData
        local sysAddData = s.addDataToWidget
        local sysLockVw = s.lockView
        local sysIsVwLock = s.isViewLocked
        local msqrt = math.sqrt
        local tonum = tonumber
        local mabs = math.abs
        local mfloor = math.floor
        local atmosphere = u.getAtmosphereDensity
        local atan = math.atan
        local systime = s.getArkTime
        local uclamp = utils.clamp
        local navCom = Nav.axisCommandManager

        local coreHalfDiag = 13
        local elementsID = c.getElementIdList()

        local eleTotalMaxHp = 0

        local function float_eq(a, b) -- float equation
            if a == 0 then
                return mabs(b) < 1e-09
            elseif b == 0 then
                return mabs(a) < 1e-09
            else
                return mabs(a - b) < math.max(mabs(a), mabs(b)) * epsilon
            end
        end
        
        local function round(num, numDecimalPlaces) -- rounds variable num to numDecimalPlaces
            local mult = 10 ^ (numDecimalPlaces or 0)
            return mfloor(num * mult + 0.5) / mult
        end

        local function addTable(table1, table2) -- Function to add two tables together
            for k,v in pairs(table2) do
                if type(k)=="string" then
                    table1[k] = v
                else
                    table1[#table1 + 1 ] = table2[k]
                end
            end
            return table1
        end

        local function saveableVariables(subset) -- returns saveable variables by catagory
            local returnSet = {}
                -- Complete list of user variables above, must be in saveableVariables to be stored on databank

            if not subset then
                addTable(returnSet, saveableVariablesBoolean)
                addTable(returnSet, savableVariablesHandling)
                addTable(returnSet, savableVariablesHud)
                addTable(returnSet, savableVariablesPhysics)
                return returnSet
            elseif subset == "boolean" then
                return saveableVariablesBoolean
            elseif subset == "handling" then
                return savableVariablesHandling
            elseif subset == "hud" then
                return savableVariablesHud
            elseif subset == "physics" then
                return savableVariablesPhysics
            end            
        end

        local function msg(msgt)
            if not msgt then return end
            if msgText ~= "empty" then 
                if not string.find(msgText, msgt) then 
                    msgText = msgText.."\n"..msgt
                    msgTimer = 7 
                end
            else 
                msgText = msgt 
            end
        end

        local function SaveDataBank(copy) -- Save values to the databank.
            local function writeData(dataList)
                for k, v in pairs(dataList) do
                    dbHud_1.setStringValue(k, jencode(v.get()))
                    if copy and dbHud_2 then
                        dbHud_2.setStringValue(k, jencode(v.get()))
                    end
                end
            end
            if dbHud_1 then
                writeData(autoVariables) 
                writeData(saveableVariables())
                s.print("Saved Variables to Datacore")
                if copy and dbHud_2 then
                    msg ("Databank copied.  Remove copy when ready.")
                end
            end
        end

        local function play(sound, ID, type)
            if (type == nil and not voices) or (type ~= nil and not alerts) or soundFolder == "archHUD" then return end
            s.playSound(soundFolder.."/"..sound..".mp3")
        end

        local function svgText(x, y, text, class, style) -- processes a svg text string, saves code lines by doing it this way
            return stringf([[<text class="%s" x=%s y=%s style="%s">%s</text>]], class or "",x, y, style or "", text)
        end
    
        local function getDistanceDisplayString(distance, places) -- Turn a distance into a string to a number of places
            places = places or 1
            local unit = "m"
            if distance > 100000 then
                -- Convert to SU
                distance = distance / 200000
                unit = "su"
            elseif distance > 1000 then
                distance = distance / 1000
                unit = "km"
            end
            return round(distance, places)..unit
        end
    
        local function FormatTimeString(seconds) -- Format a time string for display
            local minutes = 0
            local hours = 0
            local days = 0
            if seconds < 60 then
                seconds = mfloor(seconds)
            elseif seconds < 3600 then
                minutes = mfloor(seconds / 60)
                seconds = mfloor(seconds % 60) 
            elseif seconds < 86400 then
                hours = mfloor(seconds / 3600)
                minutes = mfloor( (seconds % 3600) / 60)
            else
                days = mfloor ( seconds / 86400)
                hours = mfloor ( (seconds % 86400) / 3600)
            end
            if days > 365 then return ">1y" 
            elseif days > 0 then 
                return days .. "d " .. hours .."h "
            elseif hours > 0 then
                return hours .. "h " .. minutes .. "m "
            elseif minutes > 0 then
                return minutes .. "m " .. seconds .. "s"
            elseif seconds > 0 then 
                return seconds .. "s"
            else
                return "0s"
            end
        end

        local function radarSetup()
            if radar_1 then 
                RADAR = RadarClass(c, s, u, radar_1, radar_2, warpdrive, mabs, sysDestWid, msqrt, svgText, tonum, coreHalfDiag, play, msg) 
            end
        end

    function program.radarSetup()
        radarSetup()
    end

    function program.onStart()
        -- Local functions for onStart

            local valuesAreSet = false
            local function LoadVariables()

                local function processVariableList(varList)
                    local hasKey = dbHud_1.hasKey
                    for k, v in pairs(varList) do
                        if hasKey(k) then
                            local result = jdecode(dbHud_1.getStringValue(k))
                            if result ~= nil then
                                v.set(result)
                                valuesAreSet = true
                            end
                        end
                    end
                end
                pcall(require,"autoconf/custom/duos_archhud/custom/userglobals")
                if dbHud_1 then
                    if not useTheseSettings then 
                        processVariableList(saveableVariables())
                        coroutine.yield()
                        processVariableList(autoVariables)
                    else
                        processVariableList(autoVariables)
                        msg ("Updated user preferences used.  Will be saved when you exit seat.\nToggle off useTheseSettings to use database saved values")
                        msgTimer = 5
                        valuesAreSet = false
                    end
                    coroutine.yield()
                    if valuesAreSet then
                        msg ("Loaded Saved Variables")
                    elseif not useTheseSettings then
                        msg ("Databank Found, No Saved Variables Found\nVariables will save to Databank on standing")
                        msgTimer = 5
                    end
                    if #SavedLocations>0 then customlocations = addTable(customlocations, SavedLocations) end
                else
                    msg ("No databank found. Attach one to control unit and rerun \nthe autoconfigure to save preferences and locations")
                end
                BrakeToggleStatus = BrakeToggleDefault
                userControlScheme = string.lower(userControlScheme)
                autoRoll = autoRollPreference
                adjustedAtmoSpeedLimit = AtmoSpeedLimit
                if (LastStartTime + 180) < time then -- Variables to reset if out of seat (and not on hud) for more than 3 min
                    LastMaxBrakeInAtmo = 0
                end
                LastStartTime = time
                userControlScheme = string.lower(userControlScheme)
                if string.find("keyboard virtual joystick mouse",  userControlScheme) == nil then 
                    msg ("Invalid User Control Scheme selected.\nChange userControlScheme in Lua Parameters to keyboard, mouse, or virtual joystick\nOr use shift and button in screen")
                    msgTimer = 7
                end
            
                if antigrav and not ExternalAGG then
                    if AntigravTargetAltitude == nil then 
                        AntigravTargetAltitude = coreAltitude
                    end
                    antigrav.setTargetAltitude(AntigravTargetAltitude)
                end
                if pcall(require, "autoconf/custom/duos_archhud/"..privateFile) then
                    if #privatelocations>0 then customlocations = addTable(customlocations, privatelocations) end
                end
                VectorStatus = "Proceeding to Waypoint"
                if MaxGameVelocity == -1 then 
                    adjMaxGameVelocity = C.getMaxSpeed()
                end
            end

            local function ProcessElements()
                
                local function CalculateFuelVolume(curMass, vanillaMaxVolume)
                    if curMass > vanillaMaxVolume then
                        vanillaMaxVolume = curMass
                    end
                    local f1, f2 = 0, 0
                     if ContainerOptimization > 0 then 
                        f1 = ContainerOptimization * 0.05
                     end
                     if FuelTankOptimization > 0 then 
                        f2 = FuelTankOptimization * 0.05
                     end
                    vanillaMaxVolume = vanillaMaxVolume * (1 - (f1 + f2))
					return vanillaMaxVolume            
                end

                local eleName = c.getElementNameById
                local checkTanks = (fuelX ~= 0 and fuelY ~= 0)
                local slottedTanksAtmo = _G["atmofueltank_size"]
                local slottedTanksSpace = _G["spacefueltank_size"]
                local slottedTanksRocket = _G["rocketfueltank_size"]
                for k in pairs(elementsID) do --Look for space engines, landing gear, fuel tanks if not slotted and c size
					local type = c.getElementDisplayNameById(elementsID[k])
					if stringmatch(type, '^.*Atmospheric Engine$') then
                        if stringmatch(tostring(c.getEngineTagsById(elementsID[k])), '^.*vertical.*$') and c.getElementForwardById(elementsID[k])[3]>0 then
                            UpVertAtmoEngine = true
                        end
                    end

                    if stringmatch(type, '^.*Space Engine$') then
                        SpaceEngines = true
                        if stringmatch(tostring(c.getEngineTagsById(elementsID[k])), '^.*vertical.*$') then
                            local enrot = c.getElementForwardById(elementsID[k])
                            if enrot[3] < 0 then
                                SpaceEngineVertUp = true
                            else
                                SpaceEngineVertDn = true
                            end
                        end
                    end
                    if (type == "Landing Gear") then
                        hasGear = true
                    end
                    if (type == "Dynamic Core Unit") then
                        local hp = eleMaxHp(elementsID[k])
                        if hp > 10000 then
                            coreHalfDiag = 110
                        elseif hp > 1000 then
                            coreHalfDiag = 55
                        elseif hp > 150 then
                            coreHalfDiag = 27
                        end
                    end
                    eleTotalMaxHp = eleTotalMaxHp + eleMaxHp(elementsID[k])
                    -- if checkTanks and (type == "Atmospheric Fuel Tank" or type == "Space Fuel Tank" or type == "Rocket Fuel Tank") then
                    if checkTanks and (stringmatch(type, '^.*Atmospheric Fuel Tank$') or stringmatch(type, '^.*Space Fuel Tank$') or stringmatch(type, '^.*Rocket Fuel Tank$')) then
						local hp = eleMaxHp(elementsID[k])
						local mass = eleMass(elementsID[k])
						local curMass = 0
                        local curTime = systime()
                        if (stringmatch(type, '^.*Atmospheric Fuel Tank$')) then
							local tnameHUD = ""
							local vanillaMaxVolume = 0
							local massEmpty = 0
							if (string.match(type, 'Advanced Gravity')) then
								tnameHUD = "AT ADGI"
								vanillaMaxVolume = 262.44
								massEmpty = 78.83
								if hp > 10000 then
									vanillaMaxVolume = 33592.32
									massEmpty = 12330
								elseif hp > 1300 then
									vanillaMaxVolume = 4199.04
									massEmpty = 2220
								elseif hp > 150 then
									vanillaMaxVolume = 1049.76
									massEmpty = 411.01
								end
							elseif (string.match(type, 'Advanced Optimised')) then
								tnameHUD = "AT ADOP"
								vanillaMaxVolume = 676
								massEmpty = 22.42
								if hp > 10000 then
									vanillaMaxVolume = 86528
									massEmpty = 3510
								elseif hp > 1300 then
									vanillaMaxVolume = 10816
									massEmpty = 632.75
								elseif hp > 150 then
									vanillaMaxVolume = 2704
									massEmpty = 116.91
								end
							elseif (string.match(type, 'Exotic Gravity')) then
								tnameHUD = "AT EXGI"
								vanillaMaxVolume = 171.6
								massEmpty = 177.36
								if hp > 10000 then
									vanillaMaxVolume = 22173.36
									massEmpty = 27750
								elseif hp > 1300 then
									vanillaMaxVolume = 2772
									massEmpty = 5010
								elseif hp > 150 then
									vanillaMaxVolume = 694.32
									massEmpty = 924.77
								end
							elseif (string.match(type, 'Exotic Optimised')) then
								tnameHUD = "AT EXOP"
								vanillaMaxVolume = 1144
								massEmpty = 14.35
								if hp > 10000 then
									vanillaMaxVolume = 146236
									massEmpty = 2250
								elseif hp > 1300 then
									vanillaMaxVolume = 18284
									massEmpty = 404.96
								elseif hp > 150 then
									vanillaMaxVolume = 4572
									massEmpty = 74.82
								end
							elseif (string.match(type, 'Rare Gravity')) then
								tnameHUD = "AT RAGI"
								vanillaMaxVolume = 213.16
								massEmpty = 118.24
								if hp > 10000 then
									vanillaMaxVolume = 27249.44
									massEmpty = 18500
								elseif hp > 1300 then
									vanillaMaxVolume = 3407.64
									massEmpty = 3340
								elseif hp > 150 then
									vanillaMaxVolume = 852.64
									massEmpty = 616.51
								end
							elseif (string.match(type, 'Rare Optimised')) then
								tnameHUD = "AT RAOP"
								vanillaMaxVolume = 880
								massEmpty = 17.94
								if hp > 10000 then
									vanillaMaxVolume = 112488
									massEmpty = 2810
								elseif hp > 1300 then
									vanillaMaxVolume = 14064
									massEmpty = 506.2
								elseif hp > 150 then
									vanillaMaxVolume = 3516
									massEmpty = 93.53
								end
							elseif (string.match(type, 'Uncommon Gravity')) then
								tnameHUD = "AT UNGI"
								vanillaMaxVolume = 324
								massEmpty = 52.55
								if hp > 10000 then
									vanillaMaxVolume = 41472
									massEmpty = 8220
								elseif hp > 1300 then
									vanillaMaxVolume = 5184
									massEmpty = 1480
								elseif hp > 150 then
									vanillaMaxVolume = 1296
									massEmpty = 274
								end
							elseif (string.match(type, 'Uncommon Optimised')) then
								tnameHUD = "AT UNOP"
								vanillaMaxVolume = 520
								massEmpty = 28.02
								if hp > 10000 then
									vanillaMaxVolume = 66560
									massEmpty = 4390
								elseif hp > 1300 then
									vanillaMaxVolume = 8320
									massEmpty = 790.94
								elseif hp > 150 then
									vanillaMaxVolume = 2080
									massEmpty = 146.14
								end
							else
								tnameHUD = "AT BASIC"
								vanillaMaxVolume = 400
								massEmpty = 35.03
								if hp > 10000 then
									vanillaMaxVolume = 51200
									massEmpty = 5480
								elseif hp > 1300 then
									vanillaMaxVolume = 6400
									massEmpty = 988.67
								elseif hp > 150 then
									vanillaMaxVolume = 1600
									massEmpty = 182.67
								end
							end
							
                            curMass = mass - massEmpty
                            if fuelTankHandlingAtmo > 0 then
                                vanillaMaxVolume = vanillaMaxVolume + (vanillaMaxVolume * (fuelTankHandlingAtmo * 0.2))
                            end
                            vanillaMaxVolume =  CalculateFuelVolume(curMass, vanillaMaxVolume)
                            
                            local name = eleName(elementsID[k])
                            
                            local slottedIndex = 0
                            for j = 1, slottedTanksAtmo do
                                if name == jdecode(u["atmofueltank_" .. j].getWidgetData()).name then
                                    slottedIndex = j
                                    break
                                end
                            end
                            
                            local tank = {elementsID[k], tnameHUD,
                                                        vanillaMaxVolume, massEmpty, curMass, curTime, slottedIndex}
                            atmoTanks[#atmoTanks + 1] = tank
                        end
                        if (stringmatch(type, '^.*Rocket Fuel Tank$')) then
							local tnameHUD = ""
							local vanillaMaxVolume = 0
							local massEmpty = 0
							if (string.match(type, 'Advanced Gravity')) then
								tnameHUD = "RC ADGI"
								vanillaMaxVolume = 209.952
								massEmpty = 390.19
								if hp > 65000 then
									vanillaMaxVolume = 26244
									massEmpty = 57920
								elseif hp > 6000 then
									vanillaMaxVolume = 3359.232
									massEmpty = 10630
								elseif hp > 700 then
									vanillaMaxVolume = 419.904
									massEmpty = 2000
								end
							elseif (string.match(type, 'Advanced Optimised')) then
								tnameHUD = "RC ADOP"
								vanillaMaxVolume = 540.8
								massEmpty = 110.99
								if hp > 65000 then
									vanillaMaxVolume = 67600
									massEmpty = 16470
								elseif hp > 6000 then
									vanillaMaxVolume = 8652.8
									massEmpty = 3020
								elseif hp > 700 then
									vanillaMaxVolume = 1081.6
									massEmpty = 567.5
								end
							elseif (string.match(type, 'Exotic Gravity')) then
								tnameHUD = "RC EXGI"
								vanillaMaxVolume = 138.864
								massEmpty = 877.94
								if hp > 65000 then
									vanillaMaxVolume = 17321.04
									massEmpty = 130320
								elseif hp > 6000 then
									vanillaMaxVolume = 2217.6
									massEmpty = 23920
								elseif hp > 700 then
									vanillaMaxVolume = 277.2
									massEmpty = 4490
								end
							elseif (string.match(type, 'Exotic Optimised')) then
								tnameHUD = "RC EXOP"
								vanillaMaxVolume = 914.4
								massEmpty = 71.03
								if hp > 65000 then
									vanillaMaxVolume = 114244
									massEmpty = 10540
								elseif hp > 6000 then
									vanillaMaxVolume = 14624
									massEmpty = 1940
								elseif hp > 700 then
									vanillaMaxVolume = 1828.8
									massEmpty = 363.2
								end
							elseif (string.match(type, 'Rare Gravity')) then
								tnameHUD = "RC RAGI"
								vanillaMaxVolume = 170.528
								massEmpty = 585.29
								if hp > 65000 then
									vanillaMaxVolume = 21286.8
									massEmpty = 86880
								elseif hp > 6000 then
									vanillaMaxVolume = 2724.944
									massEmpty = 15940
								elseif hp > 700 then
									vanillaMaxVolume = 341.056
									massEmpty = 2990
								end
							elseif (string.match(type, 'Rare Optimised')) then
								tnameHUD = "RC RAOP"
								vanillaMaxVolume = 703.2
								massEmpty = 88.79
								if hp > 65000 then
									vanillaMaxVolume = 87880
									massEmpty = 13180
								elseif hp > 6000 then
									vanillaMaxVolume = 11248.8
									massEmpty = 2420
								elseif hp > 700 then
									vanillaMaxVolume = 1406.4
									massEmpty = 454
								end
							elseif (string.match(type, 'Uncommon Gravity')) then
								tnameHUD = "RC UNGI"
								vanillaMaxVolume = 259.2
								massEmpty = 260.13
								if hp > 65000 then
									vanillaMaxVolume = 32400
									massEmpty = 38610
								elseif hp > 6000 then
									vanillaMaxVolume = 4147.2
									massEmpty = 7090
								elseif hp > 700 then
									vanillaMaxVolume = 460.8
									massEmpty = 1330
								end
							elseif (string.match(type, 'Uncommon Optimised')) then
								tnameHUD = "RC UNOP"
								vanillaMaxVolume = 416
								massEmpty = 138.74
								if hp > 65000 then
									vanillaMaxVolume = 52000
									massEmpty = 20590
								elseif hp > 6000 then
									vanillaMaxVolume = 6656
									massEmpty = 3780
								elseif hp > 700 then
									vanillaMaxVolume = 832
									massEmpty = 709.38
								end
							else
								tnameHUD = "RC BASIC"
								vanillaMaxVolume = 320
								massEmpty = 173.42
								if hp > 65000 then
									vanillaMaxVolume = 40000
									massEmpty = 25740
								elseif hp > 6000 then
									vanillaMaxVolume = 5120
									massEmpty = 4720
								elseif hp > 700 then
									vanillaMaxVolume = 640
									massEmpty = 886.72
								end
							end
                        
							curMass = mass - massEmpty
                            if fuelTankHandlingRocket > 0 then
                                vanillaMaxVolume = vanillaMaxVolume + (vanillaMaxVolume * (fuelTankHandlingRocket * 0.1))
                            end
                            vanillaMaxVolume =  CalculateFuelVolume(curMass, vanillaMaxVolume)
                            
                            local name = eleName(elementsID[k])
                            
                            local slottedIndex = 0
                            for j = 1, slottedTanksRocket do
                                if name == jdecode(u["rocketfueltank_" .. j].getWidgetData()).name then
                                    slottedIndex = j
                                    break
                                end
                            end
                            
                            local tank = {elementsID[k], tnameHUD,
                                                        vanillaMaxVolume, massEmpty, curMass, curTime, slottedIndex}
                            rocketTanks[#rocketTanks + 1] = tank
                        end
                        if (stringmatch(type, '^.*Space Fuel Tank$')) then
							local tnameHUD = ""
							local vanillaMaxVolume = 0
							local massEmpty = 0
							if (string.match(type, 'Advanced Gravity')) then
								tnameHUD = "SP ADGI"
								vanillaMaxVolume = 393.66
								massEmpty = 78.83
								if hp > 10000 then
									vanillaMaxVolume = 50388.48
									massEmpty = 12330
								elseif hp > 1300 then
									vanillaMaxVolume = 6298.56
									massEmpty = 2220
								elseif hp > 150 then
									vanillaMaxVolume = 1574.64
									massEmpty = 411.01
								end
							elseif (string.match(type, 'Advanced Optimised')) then
								tnameHUD = "SP ADOP"
								vanillaMaxVolume = 1014
								massEmpty = 22.42
								if hp > 10000 then
									vanillaMaxVolume = 129792
									massEmpty = 3510
								elseif hp > 1300 then
									vanillaMaxVolume = 16224
									massEmpty = 632.75
								elseif hp > 150 then
									vanillaMaxVolume = 4056
									massEmpty = 116.91
								end
							elseif (string.match(type, 'Exotic Gravity')) then
								tnameHUD = "SP EXGI"
								vanillaMaxVolume = 257.4
								massEmpty = 177.36
								if hp > 10000 then
									vanillaMaxVolume = 33260.04
									massEmpty = 27750
								elseif hp > 1300 then
									vanillaMaxVolume = 4158
									massEmpty = 5010
								elseif hp > 150 then
									vanillaMaxVolume = 1041.48
									massEmpty = 924.77
								end
							elseif (string.match(type, 'Exotic Optimised')) then
								tnameHUD = "SP EXOP"
								vanillaMaxVolume = 1716
								massEmpty = 14.35
								if hp > 10000 then
									vanillaMaxVolume = 219354
									massEmpty = 2250
								elseif hp > 1300 then
									vanillaMaxVolume = 27426
									massEmpty = 404.96
								elseif hp > 150 then
									vanillaMaxVolume = 6858
									massEmpty = 74.82
								end
							elseif (string.match(type, 'Rare Gravity')) then
								tnameHUD = "SP RAGI"
								vanillaMaxVolume = 319.74
								massEmpty = 118.24
								if hp > 10000 then
									vanillaMaxVolume = 40874.16
									massEmpty = 18500
								elseif hp > 1300 then
									vanillaMaxVolume = 5111.46
									massEmpty = 3340
								elseif hp > 150 then
									vanillaMaxVolume = 1278.96
									massEmpty = 616.51
								end
							elseif (string.match(type, 'Rare Optimised')) then
								tnameHUD = "SP RAOP"
								vanillaMaxVolume = 1320
								massEmpty = 17.94
								if hp > 10000 then
									vanillaMaxVolume = 168732
									massEmpty = 2810
								elseif hp > 1300 then
									vanillaMaxVolume = 21096
									massEmpty = 506.2
								elseif hp > 150 then
									vanillaMaxVolume = 5724
									massEmpty = 93.53
								end
							elseif (string.match(type, 'Uncommon Gravity')) then
								tnameHUD = "SP UNGI"
								vanillaMaxVolume = 486
								massEmpty = 52.55
								if hp > 10000 then
									vanillaMaxVolume = 62208
									massEmpty = 8220
								elseif hp > 1300 then
									vanillaMaxVolume = 7776
									massEmpty = 1480
								elseif hp > 150 then
									vanillaMaxVolume = 1944
									massEmpty = 274
								end
							elseif (string.match(type, 'Uncommon Optimised')) then
								tnameHUD = "SP UNOP"
								vanillaMaxVolume = 780
								massEmpty = 28.02
								if hp > 10000 then
									vanillaMaxVolume = 99840
									massEmpty = 4390
								elseif hp > 1300 then
									vanillaMaxVolume = 12480
									massEmpty = 790.94
								elseif hp > 150 then
									vanillaMaxVolume = 3120
									massEmpty = 146.14
								end
							else
								tnameHUD = "SP BASIC"
								vanillaMaxVolume = 600
								massEmpty = 35.03
								if hp > 10000 then
									vanillaMaxVolume = 76800
									massEmpty = 5480
								elseif hp > 1300 then
									vanillaMaxVolume = 9600
									massEmpty = 988.67
								elseif hp > 150 then
									vanillaMaxVolume = 2400
									massEmpty = 182.67
								end
							end
                        
							curMass = mass - massEmpty
                            if fuelTankHandlingSpace > 0 then
                                vanillaMaxVolume = vanillaMaxVolume + (vanillaMaxVolume * (fuelTankHandlingSpace * 0.2))
                            end
                            vanillaMaxVolume =  CalculateFuelVolume(curMass, vanillaMaxVolume)
                            
                            local name = eleName(elementsID[k])
                            --	s.print(name)
                            local slottedIndex = 0
                            for j = 1, slottedTanksSpace do
                                if name == jdecode(u["spacefueltank_" .. j].getWidgetData()).name then
                                    slottedIndex = j
                                    break
                                end
                            end
                            
                            local tank = {elementsID[k], tnameHUD,
                                                        vanillaMaxVolume, massEmpty, curMass, curTime, slottedIndex}
                            spaceTanks[#spaceTanks + 1] = tank
                        end
                    end
                end
                if not UpVertAtmoEngine then
                    VertTakeOff, VertTakeOffEngine = false, false
                end
            end
            
            local function SetupChecks()
                
                if gyro ~= nil then
                    gyroIsOn = gyro.isActive()
                end
                if not stablized then 
                    navCom:deactivateGroundEngineAltitudeStabilization()
                end
                if userControlScheme ~= "keyboard" then
                    sysLockVw(true)
                else
                    sysLockVw(false)
                end
                -- Close door and retract ramp if available
                if door and (inAtmo or (not inAtmo and coreAltitude < 10000)) then
                    for _, v in pairs(door) do
                        v.toggle()
                    end
                end
                if switch then 
                    for _, v in pairs(switch) do
                        v.toggle()
                    end
                end    
                if forcefield and (inAtmo or (not inAtmo == 0 and coreAltitude < 10000)) then
                    for _, v in pairs(forcefield) do
                        v.toggle()
                    end
                end
                if antigrav then
                    antigravOn = antigrav.isActive()
                    if antigravOn and not ExternalAGG then antigrav.showWidget() end
                end
                -- unfreeze the player if he is remote controlling the construct
                if isRemote() and RemoteFreeze then
                    P.freeze(true)
                else
                    P.freeze(false)
                end
                if hasGear then
                    if abvGndDet ~= -1 and not antigravOn then
                        Nav.control.deployLandingGears()
                    else
                        Nav.control.retractLandingGears()
                    end
                end
                GearExtended = Nav.control.isAnyLandingGearDeployed() or not stablized or (abvGndDet ~=-1 and (abvGndDet - 3) < LandingGearGroundHeight)
                -- Engage brake and extend Gear if either a hover detects something, or they're in space and moving very slowly
                local slow = coreVelocity:len() < 30
                if (abvGndDet ~= -1 and stabilzied) or ((not inAtmo or not stabilzied) and slow) then
                    BrakeIsOn = "Startup"
                else
                    BrakeIsOn = false
                end

                navCom:setTargetGroundAltitude(LandingGearGroundHeight)

                WasInAtmo = inAtmo

            end

            local function atlasSetup()
                --AutopilotTargetIndex = 0
                local atlasCopy = {}
                
                local function getSpaceEntry()
                    return {
                                id = 0,
                                name = { "Space", "Space", "Space"},
                                type = {},
                                biosphere = {},
                                classification = {},
                                habitability = {},
                                description = {},
                                iconPath = "",
                                hasAtmosphere = false,
                                isSanctuary = false,
                                isInSafeZone = true,
                                systemId = 0,
                                positionInSystem = 0,
                                satellites = {},
                                center = { 0, 0, 0 },
                                gravity = 0,
                                radius = 0,
                                atmosphereThickness = 0,
                                atmosphereRadius = 0,
                                surfaceArea = 0,
                                surfaceAverageAltitude = 0,
                                surfaceMaxAltitude = 0,
                                surfaceMinAltitude = 0,
                                GM = 0,
                                ores = {},
                                territories = 0,
                                noAtmosphericDensityAltitude = 0,
                                spaceEngineMinAltitude = 0,
                            }
                end

                local function getAegisEntry()
                    return {
                                id = 1000,
                                name = { "Aegis", "Aegis", "Aegis"},
                                type = {},
                                biosphere = {},
                                classification = {},
                                habitability = {},
                                description = {},
                                iconPath = "",
                                hasAtmosphere = false,
                                isSanctuary = false,
                                isInSafeZone = true,
                                systemId = 0,
                                positionInSystem = 1000,
                                satellites = {},
                                center = {13856549.3576,7386341.6738,-258459.8925},
                                gravity = 0,
                                radius = 0,
                                atmosphereThickness = 0,
                                atmosphereRadius = 0,
                                surfaceArea = 0,
                                surfaceAverageAltitude = 0,
                                surfaceMaxAltitude = 0,
                                surfaceMinAltitude = 0,
                                GM = 0,
                                ores = {},
                                territories = 0,
                                noAtmosphericDensityAltitude = 0,
                                spaceEngineMinAltitude = 0,
                            }
                end

                local altTable = { [1]=6637, [2]=3426, [4]=7580, [26]=4242, [27]=4150, [3]=21452, [6]=4498, [7]=6285, [8]=3434, [9]=5916 } -- Measured min space engine altitudes for:
                -- Madis, Alioth, Talemai, Sanctuary, Haven, Sicari, Sinnen, Thades, Teoma, Jago
                for galaxyId,galaxy in pairs(atlas) do
                    -- Create a copy of Space with the appropriate SystemId for each galaxy
                    atlas[galaxyId][0] = getSpaceEntry()
                    atlas[galaxyId][0].systemId = galaxyId
                    atlas[galaxyId][1000] = getAegisEntry()
                    atlasCopy[galaxyId] = {} -- Prepare a copy galaxy

                    for planetId,planet in pairs(atlas[galaxyId]) do
                        planet.gravity = planet.gravity/9.8
                        planet.center = vec3(planet.center)
                        planet.name = planet.name[1]
                
                        planet.noAtmosphericDensityAltitude = planet.atmosphereThickness
                        planet.spaceEngineMinAltitude = altTable[planet.id] or 0.5353125*(planet.atmosphereThickness)
                                
                        planet.planetarySystemId = galaxyId
                        planet.bodyId = planet.id
                        atlasCopy[galaxyId][planetId] = planet
                        if minAtlasX == nil or planet.center.x < minAtlasX then
                            minAtlasX = planet.center.x
                        end
                        if maxAtlasX == nil or planet.center.x > maxAtlasX then
                            maxAtlasX = planet.center.x
                        end
                        if minAtlasY == nil or planet.center.y < minAtlasY then
                            minAtlasY = planet.center.y
                        end
                        if maxAtlasY == nil or planet.center.y > maxAtlasY then
                            maxAtlasY = planet.center.y
                        end
                        if planet.center and planet.name ~= "Space" then
                            planetAtlas[#planetAtlas + 1] = planet
                        end
                    end
                end
                PlanetaryReference = PlanetRef(Nav, c, u, s, stringf, uclamp, tonum, msqrt, float_eq)
                galaxyReference = PlanetaryReference(atlasCopy)
                sys = galaxyReference[0]
                -- Setup Modular Classes
                Kinematic = Kinematics(Nav, c, u, s, msqrt, mabs)
                Kep = Keplers(Nav, c, u, s, stringf, uclamp, tonum, msqrt, float_eq)

                ATLAS = AtlasClass(Nav, c, u, s, dbHud_1, atlas, sysUpData, sysAddData, mfloor, tonum, msqrt, play, round, msg)
                planet = galaxyReference[0]:closestBody(C.getWorldPosition())
            end

        SetupComplete = false

        beginSetup = coroutine.create(function()
            
            --[[ --EliasVilld Log Code setup material.
            Logs = Logger()
            _logCompute = Logs.CreateLog("Computation", "time")
            --]]

            navCom:setupCustomTargetSpeedRanges(axisCommandId.longitudinal,
                {1000, 5000, 10000, 20000, 30000})

            -- Load Saved Variables

            LoadVariables()
            coroutine.yield() -- Give it some time to breathe before we do the rest

            -- Find elements we care about
            ProcessElements()
            coroutine.yield() -- Give it some time to breathe before we do the rest

            AP = APClass(Nav, c, u, atlas, vBooster, hover, telemeter_1, antigrav, dbHud_1, 
                mabs, mfloor, atmosphere, isRemote, atan, systime, uclamp, 
                navCom, sysUpData, sysIsVwLock, msqrt, round, play, addTable, float_eq, 
                getDistanceDisplayString, FormatTimeString, SaveDataBank, jdecode, msg)

            SetupChecks() -- All the if-thens to set up for particular ship.  Specifically override these with the saved variables if available

            coroutine.yield() -- Just to make sure

            atlasSetup()
            radarSetup()

            if HudClass then 
                HUD = HudClass(Nav, c, u, s, atlas, antigrav, hover, shield, warpdrive, weapon, mabs, mfloor, stringf, jdecode, atmosphere, eleMass, isRemote, atan, systime, uclamp, navCom, 
                    sysAddData, sysUpData, sysDestWid, sysIsVwLock, msqrt, round, svgText, play, addTable, saveableVariables, getDistanceDisplayString, FormatTimeString, elementsID, eleTotalMaxHp, msg) 
            end
            if HUD then 
                HUD.ButtonSetup() 
            end
            CONTROL = ControlClass(Nav, c, u, s, atlas, vBooster, hover, antigrav, shield, dbHud_2, gyro, screenHud_1,
                isRemote, navCom, sysIsVwLock, sysLockVw, sysDestWid, round, stringmatch, tonum, uclamp, play, saveableVariables, SaveDataBank, msg, transponder, jencode)
            if shield then SHIELD = ShieldClass(shield, stringmatch, mfloor, msg) end
            coroutine.yield()
            u.hideWidget()
            s.showScreen(true)
            s.showHelper(false)
            if screenHud_1 then screenHud_1.setCenteredText("") end
            -- That was a lot of work with dirty strings and json.  Clean up
            collectgarbage("collect")
            -- Start timers
            coroutine.yield()

            u.setTimer("apTick", 0.0166667)
            u.setTimer("hudTick", hudTickRate)
            u.setTimer("oneSecond", 1)
            u.setTimer("tenthSecond", 1/10)
            C.setDockingMode(DockingMode)
            if shield then u.setTimer("shieldTick", 0.0166667) end
            if userBase then PROGRAM.ExtraOnStart() end

            local function ecuResume()
                if ecuThrottle[1] == 0 then
                    AP.cmdThrottle(ecuThrottle[2])
                else
                    if atmosDensity > 0 then 
                        adjustedAtmoSpeedLimit = ecuThrottle[2] 
                        AP.cmdThrottle(1)
                    end
                end
            end
            ECU = string.find(s.getItem(u.getItemId())['displayName'],"Emergency") or false
            if ECU then 
                if abvGndDet > -1 and velMag < 1 and (abvGndDet - 3) < LandingGearGroundHeight then 
                    u.exit()
                else
                    if ECUHud then 
                        ecuResume()
                    else
                        if atmosDensity == 0 then
                            BrakeIsOn = "ECU Braking"
                        elseif abvGndDet == -1 then 
                            CONTROL.landingGear() 
                        end
                        if antigrav ~= nil then
                            antigrav.activate()
                            antigrav.show()
                        end
                    end
                end
            elseif ECUHud and (ecuThrottle[3]+3) > systime() then
                ecuResume()
            end
            ships = C.getDockedConstructs() 
            passengers = C.getPlayersOnBoard()
            local dockmsg
            dockmsg = #passengers>1 and "Passengers: "..(#passengers-1).." " or ""
            dockmsg = dockmsg..(#ships>0 and "Ships: "..#ships or "")
            if dockmsg ~= "" then msg("NOTICE: Docked "..dockmsg) end
            play("start","SU")
        end)
        coroutine.resume(beginSetup)
    end
    
    function program.onUpdate()
        if SetupComplete then
            Nav:update()
            if inAtmo and AtmoSpeedAssist and throttleMode then
                if throttleMode and WasInCruise then
                    -- Not in cruise, but was last tick
                    AP.cmdThrottle(0)
                    WasInCruise = false
                elseif not throttleMode and not WasInCruise then
                    -- Is in cruise, but wasn't last tick
                    PlayerThrottle = 0 -- Reset this here too, because, why not
                    WasInCruise = true
                end
            end
            if ThrottleValue then
                navCom:setThrottleCommand(axisCommandId.longitudinal, ThrottleValue)
                ThrottleValue = nil
            end
            
            if not Animating and content ~= LastContent then
                s.setScreen(content) 
            end
            LastContent = content
            if ECU and not ECUHud and atmosDensity > 0 and abvGndDet == -1 then
                CONTROL.landingGear()
            end
            if ECU and abvGndDet > -1 and velMag < 1 and (abvGndDet - 3) < LandingGearGroundHeight then 
                u.exit()
            end
            if userBase then PROGRAM.ExtraOnUpdate() end
        else
            local cont = coroutine.status (beginSetup)
            if cont == "suspended" then 
                local value, done = coroutine.resume(beginSetup)
                if done then s.print("ERROR STARTUP: "..done) end
            elseif cont == "dead" then
                SetupComplete = true
            end
        end
    end

    function program.onFlush()
        if SetupComplete then
            AP.onFlush()
            if userBase then PROGRAM.ExtraOnFlush() end
        end
    end

    function program.onStop()
        _autoconf.hideCategoryPanels()
        if antigrav ~= nil  and not ExternalAGG then
            antigrav.hideWidget()
        end
        if warpdrive ~= nil then
            warpdrive.hideWidget()
        end
        c.hideWidget()
        Nav.control.switchOffHeadlights()
        -- Open door and extend ramp if available
        if door and (atmosDensity > 0 or (atmosDensity == 0 and coreAltitude < 10000)) then
            for _, v in pairs(door) do
                v.toggle()
            end
        end
        if switch then
            for _, v in pairs(switch) do
                v.toggle()
            end
        end
        if forcefield and (atmosDensity > 0 or (atmosDensity == 0 and coreAltitude < 10000)) then
            for _, v in pairs(forcefield) do
                v.toggle()
            end
        end
        showHud = oldShowHud
        local ECUTime = 0
        if ECU then ECUTime = systime() end
        if navCom:getAxisCommandType(0) == 0 then
            ecuThrottle = {0, PlayerThrottle, ECUTime}
        else
            ecuThrottle = {1, navCom:getTargetSpeed(axisCommandId.longitudinal), ECUTime}
        end
        SaveDataBank()
        if button then
            button.activate()
        end
        if SetWaypointOnExit then AP.showWayPoint(planet, worldPos) end
        if HUD then s.print(HUD.FuelUsed("atmofueltank")..", "..HUD.FuelUsed("spacefueltank")..", "..HUD.FuelUsed("rocketfueltank")) end
        if userBase then PROGRAM.ExtraOnStop() end
        play("stop","SU")
    end

    function program.controlStart(action)
        if SetupComplete then
            CONTROL.startControl(action)
        end
    end

    function program.controlStop(action)
        if SetupComplete then
            CONTROL.stopControl(action)
        end
    end

    function program.controlLoop(action)
        if SetupComplete then
            CONTROL.loopControl(action)
        end
    end

    function program.controlInput(text)
        if SetupComplete then
            CONTROL.inputTextControl(text)
        end
    end

    function program.radarEnter(id)
        if RADAR then RADAR.onEnter(id) end
    end

    function program.radarLeave(id)
        if RADAR then RADAR.onLeave(id) end
    end

    function program.onTick(timerId)
        if timerId == "tenthSecond" then -- Timer executed ever tenth of a second
            if AP then AP.TenthTick() end
            if HUD then HUD.TenthTick() end
        elseif timerId == "oneSecond" then -- Timer for evaluation every 1 second
            if HUD then HUD.OneSecondTick() end
        elseif timerId == "msgTick" then -- Timer executed whenever msgText is applied somwehere
            if HUD then HUD.MsgTick() end
        elseif timerId == "animateTick" then -- Timer for animation
            if HUD then HUD.AnimateTick() end
        elseif timerId == "hudTick" then -- Timer for all hud updates not called elsewhere
            if HUD then HUD.hudtick() end
        elseif timerId == "apTick" then -- Timer for all autopilot functions
            if AP then AP.APTick() end
        elseif timerId == "shieldTick" then
            SHIELD.shieldTick()
        elseif timerId == "tagTick" then
            CONTROL.tagTick()
        elseif timerId == "contact" then
            RADAR.ContactTick()
        end
    end

    if userBase then 
        for k,v in pairs(userBase) do program[k] = v end 
    end  

    return program
end