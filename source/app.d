import vibe.d;

shared static this()
{
	auto settings = new HTTPServerSettings;
	settings.port = 8080;
	settings.bindAddresses = ["::1", "0.0.0.0"];

	auto router = new URLRouter;

	router.registerWebInterface(new WebInterface);
	router.get("*", serveStaticFiles("public/"));

	listenHTTP(settings, router);
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

		//auto pipes = pipeProcess(["clang-format", "-style="~style], Redirect.stdout | Redirect.stdin);
		//scope(exit) wait(pipes.pid);

		//pipes.stdin.write(code);
		//pipes.stdin.close;
		//pipes.pid.wait;

		//code = pipes.stdout.byLine.joiner.to!string;

		string selectedStyle = style;

		render!("index.dt", styles, code, selectedStyle);
	}

	string[] styles;
}
