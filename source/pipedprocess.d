import core.thread;

import std.datetime;
import std.process;

import vibe.d;
import vibe.stream.stdio;

class PipedProcess {

	private {
		ProcessPipes m_pipes;
		StdFileStream m_stdout;
		StdFileStream m_stdin;
		Thread m_waitThread;
		SysTime m_startTime;
		SysTime m_endTime;

		core.sync.mutex.Mutex m_statusMutex;
		core.sync.condition.Condition m_statusCondition;
		bool m_running = true;
		bool m_failed;
		int m_returnCode;
		string m_command;
		string[] m_args;
		void delegate()[] m_exitCallbacks;
	}

	string name;

	this(string cmd, string[] args)
	{
		m_command = cmd;
		m_args = args;
		m_startTime = Clock.currTime();
		m_statusMutex = new core.sync.mutex.Mutex;
		m_statusCondition = new TaskCondition(m_statusMutex);
		m_stdin = new StdFileStream(false, true);
		m_stdout = new StdFileStream(true, false);

		logDebugV("Waiting for process start");
		auto thr = new Thread(&waitThreadFunc);
		thr.name = "PipedProcess executor";
		thr.start();
		logDebugV(" ... process running");
		runTask(&waitTaskFunc);
	}

	@property SysTime startTime() { synchronized(m_statusMutex) return m_startTime; }
	@property SysTime endTime() { synchronized(m_statusMutex) return m_endTime; }

	@property bool running() const { synchronized(m_statusMutex) return m_running; }
	@property bool failed() const { synchronized(m_statusMutex) return m_failed; }
	@property int exitCode() const { synchronized(m_statusMutex) return m_returnCode; }

	@property OutputStream stdin() { synchronized(m_statusMutex) return m_stdin; }
	@property ConnectionStream stdout() { synchronized(m_statusMutex) return m_stdout; }

	void kill()
	{
		m_pipes.pid.kill();
	}

	void performOnExit(void delegate() del)
	{
		if (!m_running) del();
		else m_exitCallbacks ~= del;
	}

	void join()
	{
		synchronized (m_statusMutex) {
			while (m_running)
				m_statusCondition.wait();
		}
	}

	private void waitTaskFunc()
	{
		synchronized (m_statusMutex) {
			while (m_running)
				m_statusCondition.wait();
		}
		foreach (del; m_exitCallbacks) del();
	}

	private void waitThreadFunc()
	{
		scope(exit){
			synchronized (m_statusMutex) {
				m_endTime = Clock.currTime();
				m_running = false;
			}
			m_statusCondition.notifyAll();
		}
		try {
			logDebug("pipeProcess %s %s", m_command, m_args);
			auto pipes = pipeProcess(m_command ~ m_args, Redirect.stdin|Redirect.stdout|Redirect.stderrToStdout);
			m_stdin.setup(pipes.stdin);
			m_stdout.setup(pipes.stdout);
			synchronized(m_statusMutex){
				m_pipes = pipes;
			}
			m_statusCondition.notifyAll();
			auto ret = m_pipes.pid.wait();
			synchronized (m_statusMutex)
				m_returnCode = ret;
			logTrace("closing pipes");
			m_stdin.finalize();
			//m_pipes.stdin.close();
			//m_pipes.stdout.close();
		} catch (Exception e) {
			import std.encoding : sanitize;
			logError("Failed to execute process: %s", e.msg);
			logDiagnostic("Full exception: %s", e.toString().sanitize());
			synchronized (m_statusMutex)
				m_failed = true;
		}
	}
}
