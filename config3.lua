
Config = {}
Config.HeartBeat = {
    AntiCheatResource = 'es-trigger',
}

-- Target configuration
Config.Target = {
    AbnormalTriggerResetTiming = 5000,  -- v ms
    JailService = "esx_communityservice:sendToCommunityService",
    JailAmount = 200,
    SQLDriver = "oxmysql",
    WebhookURL = "https://discord.com/api/webhooks/1289581846178562088/LpGYiqefX8oCxpa0vLE-ookZYntB5feNnL4wxY9zQyA0gnHNuPCOTts6TrwmnjLfyeuM",
    TriggerWebhookURL = "https://discord.com/api/webhooks/1289593695963975680/WTYO0v6sxuxue5WQ6XqR_z6QBR-vlJbTgbL4WF1tfiPfZTiacuUlycSp40alDd5nVP2U",
    HeartBeatWebhookURL = "https://discord.com/api/webhooks/1289617775484076203/fnFms0Ji6QsmemsYGuskMh-zZ9cRW8qkYS_1rL2OU-7QIpyqMeq1jT6-ZO43cE3271sE",
    Message = "Bol si permanentne zabanovaný zo serveru ESOTEST",
}

-- Amount triggers
Config.AmountTriggers = {
    { Trigger = "esx_communityservicesex:sendToCommunityService", Values = {-1} },
    { Trigger = "esx_carthief:pay", Values = { 1100 } },
    { Trigger = "drug_sales:pay", Values = { 100, 400, 300, 250, 304 } },
}

-- Abnormal triggers
Config.AbnormalTriggers = {
    ["esx_policejob:handcuff"] = 2,
    ["InteractSound_SV:PlayOnAl"] = 50,
    ["fl:notify"] = 1,
}

-- Anti-trigger jobs
Config.Triggers = {
    { 
        EventName = "esx_policejob:handcuff", 
        Jobs = { "police", "sheriff", "fbi", "ambulance" }, 
        Reason = "debilko" 
    },
    { 
        EventName = "esx_jailer:sendToJail", 
        Jobs = { "police", "sheriff", "fbi", "ambulance" }, 
        Reason = "debilko" 
    },
}
