/**
 * Copyright (c) 2004, National Research Council of Canada
 * All rights reserved.
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this 
 * software and associated documentation files (the "Software"), to deal in the Software 
 * without restriction, including without limitation the rights to use, copy, modify, merge, 
 * publish, distribute, and/or sell copies of the Software, and to permit persons to whom the 
 * Software is furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice(s) and this licence appear in all copies of the Software or 
 * substantial portions of the Software, and that both the above copyright notice(s) and this 
 * license appear in supporting documentation.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND 
 * NONINFRINGEMENT OF THIRD PARTY RIGHTS. IN NO EVENT SHALL THE 
 * COPYRIGHT HOLDER OR HOLDERS INCLUDED IN THIS NOTICE BE LIABLE 
 * FOR ANY CLAIM, OR ANY DIRECT, INDIRECT, SPECIAL OR CONSEQUENTIAL 
 * DAMAGES, OR ANY DAMAGES WHATSOEVER (INCLUDING, BUT NOT 
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS 
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWSOEVER 
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN AN ACTION OF 
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR 
 * OTHERWISE) ARISING IN ANY WAY OUT OF OR IN CONNECTION WITH THE 
 * SOFTWARE OR THE USE OF THE SOFTWARE, EVEN IF ADVISED OF THE 
 * POSSIBILITY OF SUCH DAMAGE.
 * 
 * Except as contained in this notice, the name of a copyright holder shall NOT be used in 
 * advertising or otherwise to promote the sale, use or other dealings in this Software 
 * without specific prior written authorization.  Title to copyright in this software and any 
 * associated documentation will at all times remain with copyright holders.
 */


package com.sshtools.j2ssh.authentication;

import com.sshtools.j2ssh.io.ByteArrayReader;
import com.sshtools.j2ssh.io.ByteArrayWriter;
import com.sshtools.j2ssh.transport.InvalidMessageException;
import com.sshtools.j2ssh.transport.SshMessage;
import java.io.IOException;

public class SshMsgUserauthGssapiErrtok extends SshMessage
{

    public SshMsgUserauthGssapiErrtok()
    {
        super(65);
        errorToken = "";
    }

    public String getMessageName()
    {
        return "SSH_MSG_USERAUTH_GSSAPI_ERRTOK";
    }

    protected void constructByteArray(ByteArrayWriter bytearraywriter)
        throws InvalidMessageException
    {
        try
        {
            bytearraywriter.writeString(errorToken);
        }
        catch(IOException ioexception)
        {
            throw new InvalidMessageException("Invalid message data");
        }
    }

    protected void constructMessage(ByteArrayReader bytearrayreader)
        throws InvalidMessageException
    {
        try
        {
            errorToken = bytearrayreader.readString();
        }
        catch(IOException ioexception)
        {
            throw new InvalidMessageException("Invalid message data");
        }
    }

    public String getErrorToken()
    {
        return errorToken;
    }

    public void setErrorToken(String s)
    {
        errorToken = s;
    }

    public static final int SSH_MSG_USERAUTH_GSSAPI_ERRTOK = 65;
    private String errorToken;
}
