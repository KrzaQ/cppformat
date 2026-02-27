import vibe.vibe;

void main()
{
	auto settings = new HTTPServerSettings;
	settings.port = 8080;
	settings.bindAddresses = ["::1", "0.0.0.0"];

	auto router = new URLRouter;

	router.registerWebInterface(new WebInterface);
	router.get("*", serveStaticFiles("public/"));

	listenHTTP(settings, router);
	runApplication();
}

class WebInterface {

	this(){
		styles = [ "LLVM", "Google", "Chromium", "Mozilla", "WebKit", "file"];
	}

	void index()
	{
		auto code = "";
		auto selectedStyle = "WebKit";
		render!("index.dt", styles, code, selectedStyle);
	}

	void post(string style, string code)
	{
		import std.algorithm;
		import std.file;
		import std.conv;
		import std.math;
		import std.process;

		import pipedprocess;

		PipedProcess p = new PipedProcess("clang-format", ["-style="~style]);

		p.stdin.write(code);
		p.stdin.finalize;

		code = "";

		for(ulong toRead = 0; toRead > 0 || p.stdout.connected; toRead = p.stdout.leastSize){
			ubyte[] buf = new ubyte[toRead];
			p.stdout.read(buf);
			code ~= buf;
		}

		string selectedStyle = style;

		render!("index.dt", styles, code, selectedStyle);
	}

	string[] styles;
}
