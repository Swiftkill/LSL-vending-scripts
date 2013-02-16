// VolDetect greeter

//Change notecard content, put objects you want ot give into this box and edit box  to cover area  you want.

list name_list;
// message IMed when new people arrive. Would be read from notecar if empty
list g_lGreetings = []; //["Hello, %n! __your_text_here__"];
string g_sNotecardName = "message";

//- - - - - - - - - - - - - - - -
string strReplace(string str, string search, string replace)
{
    return llDumpList2String(llParseStringKeepNulls((str = "") + str,
        [search], []), replace);
}

// scan inventory
list    g_lInventory = [];
integer g_nNotecardLine;
key     g_kQueryId;

integer MAX_AV_COUNT = 40;

ReadInventory()
{
    if (g_lGreetings == [])
    {
        if(llGetInventoryType(g_sNotecardName) != -1)
            g_kQueryId = llGetNotecardLine(g_sNotecardName, g_nNotecardLine);
        else
            llOwnerSay("Notecard named " +g_sNotecardName +" not found.");
    }

    integer  count  = llGetInventoryNumber(INVENTORY_ALL);
    integer i;
    string s;
    string scriptName = llGetScriptName();

    for(i = 0; i < count; i++)
    {
        s =llGetInventoryName(INVENTORY_ALL,i);
        if (( s != scriptName) && ( s != g_sNotecardName)) //ignore script itself
        {
            g_lInventory = s + g_lInventory;  // best LSL-Mono way
        }
    }
}

SayGreetings(key avatar)
{
    string sOut = "";
    integer n;
    integer count = llGetListLength(g_lGreetings);
    string name = llGetDisplayName(avatar);
    
    for (n = 0; n < count; n++) 
    {
        string sAdd = strReplace(llList2String(g_lGreetings, n), "%n", name);
        if (llStringLength(sOut + sAdd) > 1023)
        {
            llInstantMessage(avatar, sOut );
            sOut = sAdd;
        } else {
            sOut += "\n" + sAdd;
        }
    }
    llInstantMessage(avatar, "\n" +sOut );
}

GiveInventory(key avatar)
{
    integer n;
    integer count = llGetListLength(g_lInventory);
    
    for (n = 0; n < count; n++) 
    {
        llGiveInventory(avatar, llList2String(g_lInventory, n));
    }

}

default
{
    state_entry()
    {
        llVolumeDetect(TRUE);
        ReadInventory();
    }

    changed(integer chg)
    {
        if (chg & CHANGED_INVENTORY) llResetScript();
    }

    on_rez(integer r)
    {
        llResetScript();
    }

    collision_start(integer total_number)
    {
        integer j;
        integer count = total_number;
        list dnames = [];
        key aname;
        for (j = 0; j < count; j++)
        {
            if (llDetectedType(j) & AGENT)
            {
                aname = llDetectedKey(j);
                if(aname != NULL_KEY)
                {
                    if (llListFindList(name_list, [aname]) == -1)
                    {
                        name_list += aname;

                        SayGreetings(aname);
                        
                        GiveInventory(aname);
                    }
                }
            }
        }
        // cleanup
        if (llGetListLength(name_list) > MAX_AV_COUNT)
        {
            name_list = llList2List(name_list, 1, -MAX_AV_COUNT/2);
        }
    }

    dataserver(key query_id, string data)
    {
        if (query_id == g_kQueryId)
        {
            if (data == EOF)
                llOwnerSay("Done reading notecard, read " + (string)(g_nNotecardLine + 1)
                    + " notecard lines.");
            else
            {
                // the first line is line 0, the second line is line 1, etc.
                g_lGreetings = g_lGreetings + data;

                ++g_nNotecardLine;
                g_kQueryId = llGetNotecardLine(g_sNotecardName, g_nNotecardLine);
            }
        }
    }

}
