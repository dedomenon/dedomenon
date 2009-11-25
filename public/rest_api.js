
/*
    The account object
*/
function Account()
{
    this.accountType = "Gold";
    this.accessKey = "asdfasdf";
    this.seceretKey = "2346574wfwf2346523465464sadf";
}


function User(username, password)
{
    this.userName = username;
    this.password = password;
    this.status = "logged out";
    this.account = null;
    this.login = function()
                {
                    if(this.userName == "mohsinhijazee@zeropoint.it")
                        if(this.password == "mohsinali.")
                            {
                                alert('You are logged in!');
                                this.status = "logged in" ;
                                this.account = new Account();
                                return this.account;
                            }
                         else
                             {
                                 alert('wrong password!');
                                 return null;
                             }
                     else
                         {
                             alert('User \'' + username + '\' does not exists.');
                             return null;
                         }
                        
                     return null;
                }
                
    this.logout = function()
                {
                    this.status = "logged out";
                    delete this.account;
                    this.account = null;
                }
}