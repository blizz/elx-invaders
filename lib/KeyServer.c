// Basic includes
#include <stdlib.h>
#include <stdio.h>
#include <string.h>


// For TCP/IP server socket to stream out keypresses
#include <unistd.h>
#include <errno.h>
#include <stdio.h>
#include <netdb.h>
#include <netinet/in.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <time.h>
#define MAX 80
#define PORT 8080
#define SA struct sockaddr
#include <signal.h>

// must use X11 to get focus and monitor keypresses.  Unable to find way to do this without the GUI.?.?.?
#include <X11/Xlib.h>

struct s_c {
    int sockfd;
    int connfd;
    struct sockaddr_in cli;
    Bool success;
};

struct s_c get_connection();
void       accept_connection(struct s_c *sc );
int        err_send(int sockfd, const void *buf, size_t len, int flags);

int main()
{
    printf("Starting up!\n");
    fflush(stdout);

    Display* myDisplay;
    Window myWindow;
    int myScreen;
    GC myGC;
    XEvent myEvent;
    unsigned long black, white;
    char* hello = "Hello world!";
    XFontStruct* myFont;

    struct s_c sc;  // socket and conn file descriptors

    char cbuffer[10] = "";

    if((myDisplay = XOpenDisplay(NULL)) == NULL)
    {
        puts("Error in conneting to X Server!");
        return -1;
    }
    myScreen = DefaultScreen(myDisplay);
    black = BlackPixel(myDisplay, myScreen);
    white = WhitePixel(myDisplay, myScreen);

    myWindow = XCreateSimpleWindow(myDisplay, RootWindow(myDisplay, myScreen), 0, 0, 640, 320, 5, black, white);

    //XSelectInput(myDisplay, myWindow, ExposureMask);
    XSelectInput(myDisplay, myWindow, KeyPressMask | KeyReleaseMask | ExposureMask);
 

    XClearWindow(myDisplay, myWindow);
    XMapWindow(myDisplay, myWindow);

    myGC = XCreateGC(myDisplay, myWindow, 0, 0);
    XSetForeground(myDisplay, myGC, black);
    XSetBackground(myDisplay, myGC, white);

    myFont = XLoadQueryFont(myDisplay, "7x14");
    XSetFont(myDisplay, myGC, myFont->fid);

    int redraw     = 0;
    int row_count  = 0;
    int col_count  = 0;


    printf("Window created.\n");
    fflush(stdout);


    printf("Getting socket.\n");
    sc = get_connection();


    int bs;

    int ec = 0;

    int send_err;

    while(1)
    {
        XNextEvent(myDisplay, &myEvent);

        printf("Event count: %d\n", ec++);

        if (myEvent.type == KeyPress)
        {
            sprintf( cbuffer, "P%x\n", myEvent.xkey.keycode );
            printf( "P:%x     %d\n", myEvent.xkey.keycode, bs );
            fflush(stdout);

            printf( "before send1 \n");
            fflush(stdout);
            signal(SIGPIPE, SIG_IGN);
            send_err = err_send(sc.connfd, cbuffer, 4, MSG_NOSIGNAL);
            switch( send_err ) 
            {
                case EPIPE      :
                    printf( "EPIPE connection lost retrying:%d\n", errno );
                    accept_connection( &sc );
                    break;
                case ECONNRESET :
                    printf( "ECONNRESET connection lost retrying:%d\n", errno );
                    accept_connection( &sc );
                    break;
            }
            printf( "after send1 \n");
            fflush(stdout);
            //write(sc.connfd, cbuffer, 4);

            redraw = 1;

            /* exit on ESC key press */
            if ( myEvent.xkey.keycode == 0x09 ) {
                printf(  "Breaking on ESCAPE CODE\n" );
                break;
            }
        }
        else if (myEvent.type == KeyRelease)
        {
            sprintf( cbuffer, "r%x\n", myEvent.xkey.keycode );
            printf(  "R:%x   %d\n", myEvent.xkey.keycode, bs );
            fflush(stdout);

            printf( "before send2 \n");
            fflush(stdout);
            signal(SIGPIPE, SIG_IGN);
            if (err_send(sc.connfd, cbuffer, 4, 0 ) < 0) printf("SE ND errored out errno:%d\n",errno);
            printf( "after send2 \n");
            fflush(stdout);
            //write(sc.connfd, cbuffer, 4);

            redraw = 1;
        }

        if(myEvent.type == Expose || redraw == 1)
        {
            redraw = 0;
            //XClearWindow(myDisplay, myWindow);

            //XDrawString(myDisplay, myWindow, myGC, 20, 20, hello, strlen(hello)); 
            XDrawString(myDisplay, myWindow, myGC, (40*col_count), 30 + (20*row_count), cbuffer, strlen(cbuffer)); 

            if (col_count>10) {
                col_count = 0;
                row_count++;
            } else {
            
                col_count++;
            }

        }   
    }

    printf("closing   sockfd:%d    connfd:%d\n",sc.sockfd,sc.connfd);

    close(sc.sockfd);

}

void accept_connection(struct s_c *sc )
{  
    int len;
    len = sizeof(sc->cli);

    sc->success = False;

    //clock_t start = clock();

    while (1)   // (  ( clock() - start ) < ( 10 * CLOCKS_PER_SEC ) ) 
    {
        if( (sc->connfd = accept(sc->sockfd, (SA*)&sc->cli, &len)) < 0 )
        {
            if( errno == EINTR )
            {
                continue;

            }else
            {
                printf("server accept failed...\n");
                fflush(stdout);
                exit(0);
            }
        }else
        {
            // connection accepted
            printf("server accept the client...\n");
            fflush(stdout);
            sc->success = True;
            break;
        }
    }   

    // Function for chatting between client and server
    
}


struct s_c get_connection()
{  
    int sockfd, connfd, len;
    struct sockaddr_in servaddr, cli;
    struct s_c sc;

    // socket create and verification
    sockfd = socket(AF_INET, SOCK_STREAM, 0);
    if (sockfd == -1) {
        printf("socket creation failed...\n");
        exit(0);
    }
    else
        printf("Socket successfully created..\n");
    bzero(&servaddr, sizeof(servaddr));

    // assign IP, PORT
    servaddr.sin_family = AF_INET;
    servaddr.sin_addr.s_addr = htonl(INADDR_ANY);
    servaddr.sin_port = htons(PORT);

    // Binding newly created socket to given IP and verification
    if ((bind(sockfd, (SA*)&servaddr, sizeof(servaddr))) != 0) {
        printf("socket bind failed... port:%d\n",PORT);
        exit(0);
    }
    else
        printf("Socket successfully bound.. port:%d\n",PORT);

    // Now server is ready to listen and verification
    if ((listen(sockfd, 5)) != 0) {
        printf("Listen failed...\n");
        exit(0);
    }
    else
        printf("Server listening..\n");

    sc.sockfd = sockfd;

    accept_connection( &sc );

    printf("sockfd:%d    connfd:%d\n",sockfd,connfd);
    if (sc.success) return(sc);

    // After chatting close the socket
    printf("timed out waiting for client on port %d...\n",PORT);
    close(sockfd);
    exit(0);
}


int err_send(int sockfd, const void *buf, size_t len, int flags) {
    int err = send(sockfd, buf, len, flags);
    if (err<0) 
    {
        switch(errno)
        {
            case EACCES       :
                printf("TCP/IP send error: EACCES \n");
                break;
            //case EAGAIN       :
            //    printf("TCP/IP send error: EAGAIN \n");
            //    break;
            case EWOULDBLOCK  :
                printf("TCP/IP send error: EWOULDBLOCK \n");
                break;
            case EALREADY     :
                printf("TCP/IP send error: EALREADY \n");
                break;
            case EBADF        :
                printf("TCP/IP send error: EBADF \n");
                break;
            case ECONNRESET   :
                printf("TCP/IP send error: ECONNRESET \n");
                break;
            case EDESTADDRREQ :
                printf("TCP/IP send error: EDESTADDRREQ \n");
                break;
            case EFAULT       :
                printf("TCP/IP send error: EFAULT` \n");
                break;
            case EINTR        :
                printf("TCP/IP send error: EINTR \n");
                break;
            case EINVAL       :
                printf("TCP/IP send error: EINVAL \n");
                break;
            case EISCONN      :
                printf("TCP/IP send error: EISCONN \n");
                break;
            case EMSGSIZE     :
                printf("TCP/IP send error: EMSGSIZE \n");
                break;
            case ENOBUFS      : 
                printf("TCP/IP send error: ENOBUFS \n");
                break;
            case ENOMEM       :
                printf("TCP/IP send error: ENOMEM \n");
                break;
            case ENOTCONN     :
                printf("TCP/IP send error: ENOTCONN \n");
                break;
            case ENOTSOCK     :
                printf("TCP/IP send error: ENOTSOCK \n");
                break;
            case EOPNOTSUPP   :
                printf("TCP/IP send error: EOPNOTSUPP \n");
                break;
            case EPIPE        :
                printf("TCP/IP send error: EPIPE \n");
                break;
            default:
                printf("TCP/IP send unknown error: %d \n", errno);
        }
    } else {
        return err;
    }
    fflush(stdout);
    return errno;
}
