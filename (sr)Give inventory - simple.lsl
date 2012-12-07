// this script is designed to give content of box _except_ itself. It can be used as is, or modified.

integer g_bGiveOnRez = TRUE;            // automatically give inventory if object is rezzed in world
integer g_bGiveOnAttach = TRUE;         // automatically give inventory if object is attached
integer g_bDetachAfterUse = TRUE;       // automatically detach
integer g_bCleanLandAfterUse = TRUE;   // automatically destroy package if rezzed on land !!WARNING!! no copy package will be lost!
                                        // but setting it to true helps to keep sandboxes clean, as newbies  people  don't know  what to do  
                                        // clearly yet
// *** FEEL FREE TO EDIT THOSE ***
string g_sDefaultFolder = ""; // if default folder is empty, GenerateFolderName() is used 
string g_sUnpackString = "Unpack";

//%n %o %f with user name, object's name and folder's name respectively
string g_sHello = "Good day, %n. This is automated package containing goods you purchased. To use them properly you should unpack them. We gladly help you with that, using this script.";
string g_sNotify = "This package would create a folder %f in your inventory and put its content there. Please, stand by...";
string g_sRemove = "Package is automatically removed.";

// name replacers (%n %o %f) do not work here. Done to avoid postponed detach event.
string g_sByeString = "Thank you for using our services, we hope you will enjoy your purchase.";

key g_kUser;

string strReplace(string str, string search, string replace) 
{
    return llDumpList2String(llParseStringKeepNulls((str = "") + str,
                                          [search], []), replace);
}

// generate folder name here
// uses package's object name if default is empty string
string GenerateFolderName()
{
    if(g_sDefaultFolder == "")
        return llGetObjectName();
    else
    {
        return g_sDefaultFolder;
    }
}

// parses string, replacing %n %o %f with user name, object's name and folder's name respectively
string parseString(string s)
{
    string res;
    res = strReplace(s, "%o", llGetObjectName());
    res = strReplace(res, "%n", llKey2Name(llGetOwner()) );
    res = strReplace(res, "%f", GenerateFolderName());
    return res;
}


list ReadInvenotory()
{
    list inventory;
    integer  count  = llGetInventoryNumber(INVENTORY_ALL);
    integer i;
    string s;
    string scriptName = llGetScriptName();
 
    for(i = 0; i < count; i++)
    {
        s =llGetInventoryName(INVENTORY_ALL,i);
        if ( s != scriptName)
        {
            // add  to to-be-give
            inventory = s + inventory;  // best LSL-Mono way
            //inventory = (inventory=[]) + inventory + s;  // best LSL way
        }
    }
    return inventory;
}

ProcessInventory(string folder)
{
    
    llOwnerSay(parseString(g_sNotify));  
    // read inventory
    list ToBeGiven = ReadInvenotory();  
    
    // do stuff with this list if you need to
    
    // give items listed
    folder  = GenerateFolderName();      
    llGiveInventoryList(g_kUser, folder, ToBeGiven);
}

GiveInventory()
{
    
    ProcessInventory(g_sDefaultFolder);

    if(llGetAttached() != 0)
    {
        if(g_bDetachAfterUse) 
        {
            llOwnerSay(parseString(g_sRemove));
            llDetachFromAvatar(); // detachm perm granted to attached objects
        }
    } 
    else
        if(g_bCleanLandAfterUse) 
        {
            llOwnerSay(parseString(g_sRemove));
            llOwnerSay(g_sByeString);
            llDie();
        }
}

default
{
    state_entry()
    {
        llSetTouchText(g_sUnpackString);  

    }

    attach(key id)
    {
        if(id != NULL_KEY) //was attached
        {
            llRequestPermissions(id, PERMISSION_ATTACH );
            g_kUser = id; // after marketplace sometimes object doesn't have proper owner and prev.owner\creator properties
                          // until object gets rezzed inworld by new owner (results of testing anno fall 2011).
                          // sometimes it's old owner.
            if(g_bGiveOnAttach) GiveInventory();
        }
        else if (llGetAttached() == 0)  
        {
            // there is false idea that id  can be null only if object detached
            // In fact, disabling scripts during script being active, or lag 
            // during detachment may cause it happen on attach. 
            llOwnerSay(g_sByeString);
        }
    }
    
    on_rez(integer param)
    {
        llOwnerSay(parseString(g_sHello));
        
        if(g_bGiveOnRez && (llGetAttached() == 0)) 
        {
            g_kUser = llGetOwner();
            GiveInventory();
        }
    }
    
    touch_start(integer total_number)
    {
        if(llDetectedKey(0))
        {
            g_kUser = llGetOwner();
            GiveInventory();
        }
    }
}


