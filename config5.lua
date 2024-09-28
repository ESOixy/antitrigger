Config = {} 
Config.HeartBeat = Config.HeartBeat or {}  
Config.HeartBeat.AntiCheatResource = 'es-trigger'  

Config.Target = {
    ["Abnormal Trigger Reset Timing"] = 5000, -- v ms
    ["jail"] = "esx_communityservice:sendToCommunityService",
    ["jailammount"] = 200,
    ["sql"] = "oxmysql",
    ["Webhook"] = "https://discord.com/api/webhooks/1289581846178562088/LpGYiqefX8oCxpa0vLE-ookZYntB5feNnL4wxY9zQyA0gnHNuPCOTts6TrwmnjLfyeuM",
    ["TriggerWebhook"] = "https://discord.com/api/webhooks/1289593695963975680/WTYO0v6sxuxue5WQ6XqR_z6QBR-vlJbTgbL4WF1tfiPfZTiacuUlycSp40alDd5nVP2U",
    ["HeartBeatWebhook"] = "https://discord.com/api/webhooks/1289617775484076203/fnFms0Ji6QsmemsYGuskMh-zZ9cRW8qkYS_1rL2OU-7QIpyqMeq1jT6-ZO43cE3271sE",
    ["Message"] = "Bol si permanentne zabanovaný zo serveru ESOTEST"
}
Config.AmountTrigger = {
    {trigger = "esx_communityservicesex:sendToCommunityService", values = {-1}},
    {trigger = "esx_carthief:pay", values = {1100}},
    {trigger = "drug_sales:pay", values = {100, 400, 300, 250, 304}}
}

-- abnormal trigger
Config.Abnormal = {
    ["esx_policejob:handcuff"] = 2,
    ["InteractSound_SV:PlayOnAl"] = 50,
    ["fl:notify"] = 1,
}

-- antitrigger job
Config.Trigger = {
    { eventName = "esx_policejob:handcuff", job = {"police", "sheriff", "fbi", "ambulance"}, reason = "debilko" },
    { eventName = "esx_jailer:sendToJail", job = {"police", "sheriff", "fbi", "ambulance"}, reason = "debilko" },
}  
