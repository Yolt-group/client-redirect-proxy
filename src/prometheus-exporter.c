#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>


/** begin metrics variables **/
unsigned long ais_proxy = 0;
unsigned long pis_proxy = 0;
unsigned long invalid_posts = 0;
unsigned long invalid_paths = 0;
unsigned long log_error = 0;
unsigned long log_info = 0;
/** end metrics variables **/

static void error(const char *msg)
{
	time_t now;
	struct tm *tm_info;
	char timestr[26];
	now = time(0);
	tm_info = localtime(&now);
	strftime(timestr, sizeof(timestr), "%Y-%m-%dT%H:%M:%S.00Z", tm_info);
	fprintf(stderr, "{\"timestamp\":\"%s\",\"level\":\"ERROR\",\"message\":\"%s, errno=%d\"}\n", timestr, msg, errno);
}

/**
 * Write metrics to a temporary file and then move that file to
 * metrics_filename atomically.
 */
static void write_metrics_file()
{
	FILE *tmpfile = fopen("/tmp/metrics.tmp", "w");
	if (tmpfile == 0) {
		error("cannot open file /tmp/metrics.tmp");
		return;
	}
	/* ais_proxy */
	fprintf(tmpfile, "# HELP ais_proxy Number of requests that have been proxied to ais.\n");
	fprintf(tmpfile, "# TYPE ais_proxy counter\n"); 
	fprintf(tmpfile, "ais_proxy %lu\n", ais_proxy);
	/* pis_proxy */
	fprintf(tmpfile, "# HELP pis_proxy Number of requests that have been proxied to pis.\n");
	fprintf(tmpfile, "# TYPE pis_proxy counter\n"); 
	fprintf(tmpfile, "pis_proxy %lu\n", pis_proxy);
	/* invalid_posts */
	fprintf(tmpfile, "# HELP invalid_posts Number of POST requests without a state parameter.\n"); 
	fprintf(tmpfile, "# TYPE invalid_posts counter\n"); 
	fprintf(tmpfile, "invalid_posts %lu\n", invalid_posts);
	/* invalid_paths */
	fprintf(tmpfile, "# HELP invalid_paths Number of requests made with an invalid path. We return 410 gone.\n"); 
	fprintf(tmpfile, "# TYPE invalid_paths counter\n"); 
	fprintf(tmpfile, "invalid_paths %lu\n", invalid_paths);
	/* Fake logback metrics (in line with Java apps) so we can see errors on kube dashboard */
	fprintf(tmpfile, "# TYPE logback_events_total counter\n");
	fprintf(tmpfile, "logback_events_total{level=\"error\"} %lu\n", log_error);
	fprintf(tmpfile, "logback_events_total{level=\"info\"} %lu\n", log_info);
	/* Close the file (flush to disk) */
	fclose(tmpfile);
	/* This is atomic */
	if (rename("/tmp/metrics.tmp", "/tmp/metrics") != 0) {
		error("rename failed"); 
	}
}

int main(int argc, char *argv[])
{
	/* An input line of text read from stdin */
	static char line[4096];
	/* When did we last write out the metrics to file? */
	time_t last_written = 0;
	time_t now = 0;
	while (fgets(line, sizeof(line), stdin) != 0) {
	    /* Print the line to stdout. */
		printf("%s", line);

		if (strstr(line, "OK: proxy to ais")) {
			++ais_proxy;
		}
		if (strstr(line, "OK: proxy to pis")) {
			++pis_proxy;
		}
		if (strstr(line, "KO: post without valid state")) {
			++invalid_posts;
		}
		if (strstr(line, "KO, non-root URL request")) {
			++invalid_paths;
		}
		if (strstr(line, "\"level\":\"ERROR\"")) {
			++log_error;
		}
		if (strstr(line, "\"level\":\"INFO\"")) {
			++log_info;
		}

		/* Write the metrics to file at most every two seconds. */
		now = time(0);
		if (now - last_written > 1) {
			write_metrics_file();
			last_written = now;
		}
	}
	
	write_metrics_file();

	return 0;
}
