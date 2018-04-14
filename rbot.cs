using System;
using System.Collections.Generic;
class rbot{
      public static void Main() {
          //Change the value of lenght value to change the count of agents
              int length=5;
              Console.WriteLine("Enter the names of all the "+ length +" Agents(Press [Enter] after entering each name).");
              string [] agents = new string[length];
              string name= string.Empty;
              for(int i=0; i<length; i++)
              {
                  int n=i+1;
                  Console.WriteLine("Enter the name of " + n + "th Agent." );
                  name=Console.ReadLine();
                  agents[i]=name;
              }
              Console.WriteLine("Enter the number of user Requests each agents can handle.");
              int Clients=Int32.Parse(Console.ReadLine());
              Console.WriteLine("----------Output----------");
              int [] ClientsPerAgents = new int[length];
              int ClientsByAgents=Clients/length;
              if (ClientsByAgents > 1 )
              {
                  int ClientsPerAgentsInitial= Clients%length;
                  //Console.WriteLine("Check="+ClientsByAgents+" : Initial="+ClientsByAgents + " : " + ClientsPerAgentsInitial);
                  for(int i=0;i<length;i++)
                  {
                      ClientsPerAgents[i]=ClientsByAgents;
                  }
                  for(int i=0;i<ClientsPerAgentsInitial;i++)
                  {
                      ClientsPerAgents[i]=ClientsPerAgents[i]+1;
                  }
              }
              else
              {
                  for(int i=0;i<Clients;i++)
                  {
                      ClientsPerAgents[i]=1;
                  }
              }
              for (int i=0;i<length;i++)
              {
                  Console.WriteLine("Agent Name : " + agents[i] + " Clients to agent : " + ClientsPerAgents[i]);
              }
      }
}
