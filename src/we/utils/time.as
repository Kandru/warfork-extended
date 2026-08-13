// localTime is wall-clock unix seconds (engine time_t), not milliseconds.

uint WE_UnixSeconds()
{
    return uint( localTime );
}

String WE_UnixTimestamp()
{
    return "" + WE_UnixSeconds();
}

bool WE_IsLeapYear( int year )
{
    if ( ( year % 400 ) == 0 )
        return true;
    if ( ( year % 100 ) == 0 )
        return false;
    return ( ( year % 4 ) == 0 );
}

int WE_DaysInMonth( int year, int month )
{
    if ( month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12 )
        return 31;
    if ( month == 4 || month == 6 || month == 9 || month == 11 )
        return 30;
    if ( WE_IsLeapYear( year ) )
        return 29;
    return 28;
}

String WE_Pad2( int value )
{
    if ( value < 10 )
        return "0" + value;
    return "" + value;
}

// Human-readable UTC from unix seconds: YYYY-MM-DD HH:MM:SS
String WE_FormatUnixUTC( uint unixSec )
{
    int days = int( unixSec / 86400 );
    int rem = int( unixSec % 86400 );
    int hour = rem / 3600;
    int minute = ( rem % 3600 ) / 60;
    int second = rem % 60;

    int year = 1970;
    while ( true )
    {
        int diy = WE_IsLeapYear( year ) ? 366 : 365;
        if ( days < diy )
            break;
        days -= diy;
        year++;
    }

    int month = 1;
    while ( month <= 12 )
    {
        int dim = WE_DaysInMonth( year, month );
        if ( days < dim )
            break;
        days -= dim;
        month++;
    }

    int day = days + 1;
    return "" + year + "-" + WE_Pad2( month ) + "-" + WE_Pad2( day )
         + " " + WE_Pad2( hour ) + ":" + WE_Pad2( minute ) + ":" + WE_Pad2( second );
}

String WE_HumanTimeNow()
{
    return WE_FormatUnixUTC( WE_UnixSeconds() );
}
