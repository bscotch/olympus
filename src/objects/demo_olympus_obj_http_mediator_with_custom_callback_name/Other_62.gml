/// {@link https://manual-en.yoyogames.com/#t=The_Asset_Editors%2FObject_Properties%2FAsync_Events%2FHTTP.htm}
if async_load[?"id"] == http_handle{
	if async_load[?"status"] == 0{
		_callback(async_load);
	}
} 