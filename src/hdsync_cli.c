/* HDSync
   
 (c) 2011 Nederlands Instituut voor Mediakunst (NIMk)
     2011 Denis Roio <jaromil@nimk.nl>

     This program is free software: you can redistribute it and/or modify
     it under the terms of the GNU Affero General Public License as
     published by the Free Software Foundation, either version 3 of the
     License, or (at your option) any later version.
     
     This program is distributed in the hope that it will be useful,
     but WITHOUT ANY WARRANTY; without even the implied warranty of
     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
     GNU Affero General Public License for more details.
     
     You should have received a copy of the GNU Affero General Public License
     along with this program.  If not, see <http://www.gnu.org/licenses/>

*/

#include <config.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>

#include <errno.h>

#include <avremote.h>
#include <parsers.h>

// our exit codes are shell style: 1 is error, 0 is success
#define ERR 1

// uncomment to debug
#define DEBUG 1


char filename[512];
char command[64];
char server[512];
int port = 0;

parser_f *parser = NULL;

// we use only getopt, no _long
static const char *short_options = "-hvs:p:";

void cmdline(int argc, char **argv) {
  command[0] = 0;
  filename[0] = 0;
  server[0] = 0;

  int res, optlen;
  do {
    res = getopt(argc, argv, short_options);
    switch(res) {
    case 'h':
      fprintf(stderr,
	      "%s %s - prepare and start synced playback of video across devices\n"
	      "\n"
	      " Copyright (C) 2011 Jaromil @ NIMk.nl Artlab , License GNU AGPL v3+\n"
	      " This is free software: you are free to change and redistribute it.\n"
	      " The latest HDSync sourcecode is published on <%s>\n"
	      "\n"
	      "Syntax: hdsync [options] [command] [args...]\n"
	      "\n"
	      "Commands:\n"
	      "\n"
	      " prepare     prepare a file ready to sync\n"
	      " start       start the video that was prepared\n"
	      "\n"
	      "Options:\n"
	      "\n"
	      " -s          network address or hostname of the media server\n"
	      " -p          port on which the UPNP AVTransport daemon is listening\n"
	      " -t          dry run to test without a server (print out rendered xml)\n"
	      "\n"
	      " -h          print this help\n"
	      " -v          version information for this tool\n"
	      "\n"
	      "For more informations on HDSync see: http://nimk.nl/syncstarter\n"
	      "Please report bugs on <http://bugs.dyne.org>.\n",
	      PACKAGE, VERSION, PACKAGE_URL);
      exit(0);

    case 'v':
      fprintf(stderr,"%s - simple commandline tool to send AVTransport commands over UPNP\n"
	      "version %s by Jaromil - Netherlands Media Art Institute\n"
	      "Copyright (C) 2011 NIMk Artlab, License GNU AGPL v3+\n"
	      "This is free software: you are free to change and redistribute it\n",
	      PACKAGE, VERSION);
      exit(0);
      
    case 's':
      snprintf(server,511,"%s",optarg);
      break;

    case 'p':
      sscanf (optarg, "%u", &port);
      break;

    case '?':
      fprintf(stderr,"unrecognized option: %s\n",optarg);
      break;
      
    case 1:
      if(!command[0]) {
	snprintf(command,63,"%s",optarg);
      } else
	snprintf(filename,511,"%s",optarg);
      break;
    default:
      break;
    }

  } while(res != -1);
}


int main(int argc, char **argv) {
  upnp_t *upnp;
  int found;

  cmdline(argc, argv);

  upnp = create_upnp();
  
  // no server specified, force localhost
  if(!server[0]) sprintf(server,"localhost");

  // commandline or detection found explicit addresses
  snprintf(upnp->hostname, MAX_HOSTNAME_SIZE-1,"%s",server);
  upnp->port = port;

  if ( connect_upnp (upnp) < 0 )
    {
      fprintf(stderr,"can't connect to %s:%u: operation aborted.\n", server, port);
      exit(ERR);
    }  

  /* command parsing is a cascade switch on single letters
     this is supposedly faster than strcmp. mapping:

     P repare
     S tart

  */
  switch(command[0]) {

  case 'p': // Prepare

    // load, play and pause in sequence
    // break and reopen connection in between

    // was connected already

    // load
    render_uri_meta(upnp,filename);
    render_upnp(upnp,"SetAVTransportURI", upnp->meta);

    // must re-connect socket between commands
    send_upnp(upnp);
    recv_upnp(upnp, 1000);
    close(upnp->sockfd);
    upnp->sockfd = 0;

    connect_upnp(upnp);
    render_upnp(upnp,"Play","<Speed>1</Speed>");

    send_upnp(upnp);
    recv_upnp(upnp, 1000);
    close(upnp->sockfd);
    upnp->sockfd = 0;

    connect_upnp(upnp);
    render_upnp(upnp,"Pause","");
    send_upnp(upnp);
    recv_upnp(upnp, 1000);
    break;

  case 's': // start sync
    // was connected already
    render_upnp(upnp,"Play","<Speed>1</Speed>");
    send_upnp(upnp);
    recv_upnp(upnp, 1000);
    break;

    /*
  case 'g': // dump a parsable full state of the device  
    render_upnp(upnp,"GetTransportInfo","");
    parser = GetTransportInfo;
    
    break;

  case 'm': // set the playmode:
    // "NORMAL", "REPEAT_ONE", "REPEAT_ALL", "RANDOM"
    {
      char tmp[256];
      snprintf(tmp,255,"<NewPlayMode>%s</NewPlayMode>",filename);
      render_upnp(upnp,"SetPlayMode",tmp);
    }
    break;

  case 'j': // jump aka seek
    // <SeekMode> and <SeekTarget>
    {
      char tmp[512];
      snprintf(tmp,511,"<Unit>REL_TIME</Unit><Target>%s</Target>",filename);
      render_upnp(upnp,"Seek",tmp);
    }
    break;
    */
  default:
    if(!command[0]) break;
    fprintf(stderr,"warning: command not recognized\n");
    exit(1);
  }

  free_upnp(upnp);

  exit(0);
}
