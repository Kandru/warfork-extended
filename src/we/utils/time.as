String WE_UnixTimestamp()
{
    return "" + ( localTime / 1000 );
}

String WE_HumanTimeNow()
{
    return "unix:" + WE_UnixTimestamp();
}

uint WE_UnixSeconds()
{
    return uint( localTime / 1000 );
}
