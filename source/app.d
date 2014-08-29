import vibe.d;

shared static this()
{
	auto settings = new HTTPServerSettings;
	settings.port = 8080;
	settings.bindAddresses = ["::1", "127.0.0.1"];

	auto router = new URLRouter;

	router.registerWebInterface(new WebInterface);

	listenHTTP(settings, router);

	//logInfo("Please open http://127.0.0.1:8080/ in your browser.");
}

class WebInterface {
	private {
		// stored in the session store
		//SessionVar!(bool, "authenticated") ms_authenticated;
	}

	this(){
		styles = ["default"];
	}

	void index()
	{
		auto code = "";
		render!("index.dt", styles, code);
		//renderCompat!("index.dt", string[], "styles")(styles);
	}

	void post(string style, string code)
	{
		import std.algorithm;
		import std.file;
		import std.conv;
		import std.math;
		import std.process;
		auto pipes = pipeProcess("clang-format", Redirect.stdout | Redirect.stdin);
		scope(exit) wait(pipes.pid);

		pipes.stdin.write(code);
		pipes.stdin.close;
		pipes.pid.wait;

		//char[] buf = new char[min(code.length * 2, 1048576)];

		//code = pipes.stdout.byChunk(4096).joiner.array.map(v => v.to!char).to!string;

		code = pipes.stdout.byLine.joiner("\r\n").to!string;

		render!("index.dt", styles, code);
	}

	string[] styles;
}
