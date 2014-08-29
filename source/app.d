import vibe.d;

shared static this()
{
	auto settings = new HTTPServerSettings;
	settings.port = 8080;
	settings.bindAddresses = ["::1", "0.0.0.0"];

	auto router = new URLRouter;

	router.registerWebInterface(new WebInterface);

	listenHTTP(settings, router);

	//logInfo("Please open http://127.0.0.1:8080/ in your browser.");
}

class WebInterface {

	this(){
		styles = [ "LLVM", "Google", "Chromium", "Mozilla", "WebKit"];
	}

	void index()
	{
		auto code = "";
		render!("index.dt", styles, code);
	}

	void post(string style, string code)
	{
		import std.algorithm;
		import std.file;
		import std.conv;
		import std.math;
		import std.process;
		auto pipes = pipeProcess(["clang-format", "style="~style], Redirect.stdout | Redirect.stdin);
		scope(exit) wait(pipes.pid);

		pipes.stdin.write(code);
		pipes.stdin.close;
		pipes.pid.wait;

		code = pipes.stdout.byLine.joiner.to!string;

		render!("index.dt", styles, code);
	}

	string[] styles;
}
