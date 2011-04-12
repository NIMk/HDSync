/* avremote 0.1
 *
 *  (c) 2011 Nederlands Instituut voor Mediakunst (NIMk)
 *      2011 Denis Roio <jaromil@dyne.org>
 *
 * This source code is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Public License as published 
 * by the Free Software Foundation; either version 3 of the License,
 * or (at your option) any later version.
 *
 * This source code is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * Please refer to the GNU Public License for more details.
 *
 * You should have received a copy of the GNU Public License along with
 * this source code; if not, write to:
 * Free Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
 
#include <errno.h>

#include <libgen.h>

// our exit codes are shell style: 1 is error, 0 is success
#define ERR 1

// uncomment to debug
#define DEBUG 1

char action [128];
char message[1024];

typedef struct {
  char *hostname;
  int port;
  int sockfd;

  char *msg;
  char *hdr;
  char *res;

  size_t size;
} upnp_t;

upnp_t upnp = { NULL, -1, -1, NULL, NULL, 0 };

upnp_t *create_upnp() {
  upnp_t *upnp;
  upnp = calloc(1,sizeof(upnp_t));
  upnp->hostname = calloc(256,sizeof(char));
  upnp->port = -1;
  upnp->sockfd = -1;

  upnp->msg = (char*) calloc(1024,sizeof(char));
  upnp->hdr = (char*) calloc(512,sizeof(char));
  upnp->res = (char*) calloc(1401,sizeof(char));

  upnp->size = -1;

  return(upnp);
} 

void free_upnp(upnp_t *upnp) {
  if(!upnp) {
    fprintf(stderr,"error: upnp object is NULL (%s)",__PRETTY_FUNCTION__);
    return;
  }
  if(upnp->sockfd > 0) close(upnp->sockfd);
  if(upnp->hostname) free(upnp->hostname);
  if(upnp->msg) free(upnp->msg);
  if(upnp->hdr) free(upnp->hdr);
  if(upnp->res) free(upnp->res);

  free(upnp);
}

int check_upnp(upnp_t *upnp, const char *caller) {
  int res = 1;
  if(!upnp) {
    fprintf(stderr,"error: upnp object is NULL (%s)",caller);
    res = 0;
  }
  if(!upnp) {
    fprintf(stderr,"error: upnp is not connected (%s)",caller);
    res = 0;
  }
  return(res);
}

int connect_upnp(upnp_t *upnp, char *hostname, int port) {
  struct sockaddr_in serveraddr;
  struct hostent *server;
  int sockfd;

  if( upnp->sockfd > 0 ) {
    fprintf(stderr,"error: upnp connection already open on socket %u\n",upnp->sockfd);
    return(-1);
  }

  /* socket: create the socket */
  sockfd = socket(AF_INET, SOCK_STREAM, 0);
  if (sockfd < 0) {
    error("error: can't open socket (%s)\n", strerror(errno));
    return(-1);
  }

  /* gethostbyname: get the server's DNS entry */
  server = gethostbyname(hostname);
  if (server == NULL) {
    error("error: no such host as %s (%s)\n", hostname, strerror(errno));
    return(-1);
  }
  
  /* build the server's Internet address */
  bzero((char *) &serveraddr, sizeof(serveraddr));
  serveraddr.sin_family = AF_INET;
  bcopy((char *)server->h_addr, 
	(char *)&serveraddr.sin_addr.s_addr, server->h_length);
  serveraddr.sin_port = htons(port);
  
  /* connect: create a connection with the server */
  if (connect(sockfd, &serveraddr, sizeof(serveraddr)) < 0) {
    error("error: can't connect (%s)\n",strerror(errno));
    return(-1);
  }

  snprintf(upnp->hostname, 255, "%s",hostname);
  upnp->port = port;
  upnp->sockfd = sockfd;

  return(sockfd);
}

void render_file_meta() {
  /*
    "<DIDL-Lite xmlns=\"urn:schemas-upnp-org:metadata-1-0/DIDL-Lite\""
	   "xmlns:dc=\"http://purl.org/dc/elements/1.1/\""
	   "xmlns:upnp=\"urn:schemas-upnp-org:metadata-1-0/upnp/\">"
	   "<item id=\"2$file\" parentID=\"2$parentDir\" restricted=\"0\">"
	   "<dc:title>$fileName</dc:title><dc:date></dc:date><upnp:class>object.item.imageItem</upnp:class><dc:creator></dc:creator><upnp:genre></upnp:genre><upnp:artist></upnp:artist><upnp:album></upnp:album><res protocolInfo=\"file-get:*:*:*:DLNA.ORG_OP=01;DLNA.ORG_CI=0;DLNA.ORG_FLAGS=00000000001000000000000000000000\" protection=\"\" tokenType=\"0\" bitrate=\"0\" duration=\"\" size=\"$fileSize\" colorDepth=\"0\" ifoFileURI=\"\" resolution=\"\">$uri</res></item></DIDL-Lite>"
  */
}

void render_upnp(upnp_t *upnp, char *action, char *arg) {
  // blank message first
  snprintf(upnp->msg,1023,"<?xml version=\"1.0\" encoding=\"utf-8\"?>\r\n"
	   "<s:Envelope s:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" "
	   "xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\">\r\n<s:Body>\r\n"
	   "<u:%s xmlns:u=\"urn:schemas-upnp-org:service:AVTransport:1\">\r\n"
	   "<InstanceID>0</InstanceID>\r\n%s\r\n</u:%s>\r\n</s:Body>\r\n</s:Envelope>\r\n", 
	   action, arg, action);

  upnp->size = strlen(upnp->msg);

  snprintf(upnp->hdr,1023,"POST /MediaRenderer_AVTransport/control HTTP/1.0\r\n"
	   "SOAPACTION: \"urn:schemas-upnp-org:service:AVTransport:1#%s\"\r\n"
	   "CONTENT-TYPE: text/xml ; charset=\"utf-8\"\r\n"
	   "HOST: %s:%u\r\n"
	   "Connection: close\r\n"
	   "Content-Length: %u\r\n"
	   "\r\n", action, upnp->hostname, upnp->port, upnp->size);
}

int send_upnp(upnp_t *upnp) {
  int res;
  int hdrlen = strlen(upnp->hdr);
  res = write(upnp->sockfd,upnp->hdr,hdrlen);
  if(res != hdrlen)
    fprintf(stderr,"send upnp header wrote only %u of %u bytes",res, hdrlen);
  // TODO: check success
  res = write(upnp->sockfd,upnp->msg,upnp->size);
  if(res != upnp->size)
    fprintf(stderr,"send upnp message wrote only %u of %u bytes",res, upnp->size);

#ifdef DEBUG
  fprintf(stderr,"sent %u bytes header, %u bytes message\n",hdrlen, res);
  fprintf(stderr,"header:\n\n%s\n\n",upnp->hdr);
  fprintf(stderr,"message:\n\n%s\n\n",upnp->msg);
#endif

  return(1);
}

int recv_upnp(upnp_t *upnp) {
  int res;
  res = read(upnp->sockfd, upnp->res,1400);
#ifdef DEBUG
  fprintf(stderr,"response:\n\n%s\n",upnp->res);
#endif
  return(1);
}

int load(upnp_t *upnp, char *file) {
  char meta[1024];
  if(!check_upnp(upnp, __PRETTY_FUNCTION__)) return(0);
  //  render_file_meta(file, meta);
  // TODO
}

int play(upnp_t *upnp) {
  if(!check_upnp(upnp, __PRETTY_FUNCTION__)) return(0);
  render_upnp(upnp,"Play","<Speed>1</Speed>");
  send_upnp(upnp);
  return(1);
}

int stop(upnp_t *upnp) {
  if(!check_upnp(upnp, __PRETTY_FUNCTION__)) return(0);
  render_upnp(upnp,"Stop","");
  send_upnp(upnp);
  return(1);
}

int get_trans_info(upnp_t *upnp) {
  if(!check_upnp(upnp, __PRETTY_FUNCTION__)) return(0);
  render_upnp(upnp,"GetTransportInfo","");
  send_upnp(upnp);
  recv_upnp(upnp);
  return(1);
}

int main(int argc, char **argv) {
  int sock, port, n;
  char hostname[512];
  char command[128];

  /* check command line arguments */
  if (argc < 4) {
    fprintf(stderr,"usage: %s <hostname> <port> <command> [filename]\n", argv[0]);
    exit(ERR);
  }
  snprintf(hostname,511,"%s",argv[1]);
  port = atoi(argv[2]);

  snprintf(command,127,"%s",argv[3]);

  upnp_t *upnp;
  upnp = create_upnp();

  if ( connect_upnp(upnp, hostname, port) < 0 ) {
    fprintf(stderr,"error: connection failed\n");
    exit(ERR);
  }  

  fprintf(stderr,"socket: %u\n",upnp->sockfd);

  switch(command[0]) {
  case 'p': // play
    play(upnp);
    break;
  case 's':
    stop(upnp);
    break;
  case 'g':
    get_trans_info(upnp);
    break;
  default:
    fprintf(stderr,"error: command not understood.\n");
    break;
  }

  free_upnp(upnp);

  exit(0);
}
