# This is the Server Module where the GenServers are created.
# All the handle methods and server methods are defined here.

defmodule Server do
  use GenServer
  
  def start(arg) do
    GenServer.start_link(__MODULE__, arg) 
  end
  
  def init(arg) do
    {:ok, {arg, 0, 0, %{}} }
  end

  def handle_call({:fetch_arg},_from, state) do
    id=elem(state,0)
    {:reply, id, state}
  end
  
  def handle_call({:fetch_succ},_from, state) do
    id=elem(elem(state,1),1)
    {:reply, id, state}
  end

  def handle_call({:fetch_pred},_from, state) do
    id=elem(elem(state,2),1) 
    {:reply, id, state}
  end  

  def handle_call({:fetch_finger_table},_from, state) do
    id=elem(state,3)
    {:reply, id, state}
  end  

  def handle_cast({:set_neig, node_id, successor, predecessor}, state) do
    {:noreply, {node_id, successor, predecessor, %{}}}
  end

  def handle_cast({:set_finger_table, node_id, successor, predecessor, map}, state) do
    {:noreply, {node_id, successor, predecessor, map}}
  end
  
  def handle_info(:kill_me, state) do
    {:stop, :normal, state}
  end

  def terminate(_, state) do
    IO.inspect "Look! I'm dead."
  end

end



defmodule Main do
  import RandomString

  # This is the Main method of the project which takes the arguments 
  # and passes them to appropriate functions to start the chord application.

  def main(args) do
    process_list = args
    if(length(process_list)!=2) do
      IO.puts("Invalid number of arguments provided")
    else
      {numNodes, d1} = Integer.parse(Enum.at(process_list, 0))
      {numRequests, d1} = Integer.parse(Enum.at(process_list, 1))
      createNodes(numNodes, numRequests)
    end
  end

  def kill_node(node_list) do
    pid = elem(Enum.at(node_list,0),1)
    IO.inspect "killing"
    send(pid, :kill_me_pls)
  end

  # The queryKeys method query all the nodes with randomly generated keys for 
  # for numRequests times.

  def queryKeys(numNodes, node_list, numRequests, key_map) do
    keys = Map.keys(key_map)
    queryKeys = Enum.take_random(keys, numRequests)
    IO.puts "The randomly selected keys to query are:"
    IO.inspect queryKeys
    IO.puts " "
    overall_hops = Enum.reduce(queryKeys, 0, fn(x), acc1 -> 
      hops = Enum.reduce(node_list, 0, fn(y),acc -> 
          pid = elem(y, 1)
          IO.puts "The key is being queried at the node"
          IO.inspect pid
          acc = acc + findKey(key_map, pid, x, 0)
      end)
      # IO.puts hops
      hop_average = hops/numNodes
      # IO.puts "Round #{acc1} is running for query key #{x}"
      IO.puts "For the key #{x}, the hop average #{hop_average}"
      IO.puts "--------Round over--------"
      IO.puts " "
      acc1 = acc1 + hop_average
    end)
    overall_hop_average = overall_hops / numRequests
    IO.puts "   "
    IO.puts "All requests are queried successfully"
    IO.puts "Overall hop average is #{overall_hop_average}"
  end

  # This method creates numNodes number of nodes in the peer to peer network.

  def createNodes(numNodes, numRequests) do
    key_space_size_tpl = getKeySpaceSizeAndM(numNodes, 1)
    key_space_size = elem(key_space_size_tpl, 0)
    m = elem(key_space_size_tpl, 1)
    lst = Enum.sort(Enum.take_random(0..key_space_size-1, numNodes))
    node_list = Enum.map(lst, fn(x) -> Server.start(x) end)
    createChord(node_list, key_space_size, numNodes, numRequests, m)
  end

  # This method creates chord overlay network with successors and predecessors
    
  def createChord(node_list, key_space_size, numNodes, numRequests, m) do
    Enum.map(node_list, fn(x) ->    
      ind = Enum.find_index(node_list, fn y -> y == x end)
      last_ind = length(node_list)-1
      cond do
        ind == last_ind ->
          pid = elem(x, 1)
          successor = Enum.at(node_list,0)
          predecessor = Enum.at(node_list,ind-1)
          node_id = GenServer.call(pid, {:fetch_arg})
          GenServer.cast(pid, {:set_neig, node_id, successor, predecessor})
          
        ind == 0 -> 
          pid = elem(x, 1)
          successor = Enum.at(node_list,1)
          predecessor = Enum.at(node_list,length(node_list)-1)
          node_id = GenServer.call(pid, {:fetch_arg})
          GenServer.cast(pid, {:set_neig, node_id, successor, predecessor})

        true ->
          pid = elem(x, 1)
          successor = Enum.at(node_list,ind+1)
          predecessor = Enum.at(node_list,ind-1)
          node_id = GenServer.call(pid, {:fetch_arg})
          GenServer.cast(pid, {:set_neig, node_id, successor, predecessor}) 
      end
    end)

    key_map = createKeys(node_list, key_space_size, m)
    createFingertable(node_list, m, key_map, key_space_size)
    queryKeys(numNodes, node_list, numRequests, key_map)
    kill_node(node_list)
    queryKeys(numNodes, node_list, numRequests, key_map)
  end

  # This method creates finger table with m entries for all the nodes
  
  def createFingertable(node_list, m, key_map, key_space_size) do
    Enum.map(node_list, fn(x) -> 

      pid = elem(x, 1)
      predecessor = GenServer.call(pid, {:fetch_pred})
      successor = GenServer.call(pid, {:fetch_succ})
      node_id = GenServer.call(pid, {:fetch_arg})
      temp_map =  Enum.reduce(0..m-1, %{}, fn(y), acc -> 
                    key_id = rem(node_id + trunc(:math.pow(2,y)), key_space_size)
                    Map.put(acc, key_id, elem(key_map[key_id],0))
                  end)
      
      GenServer.cast(pid, {:set_finger_table, node_id, successor, predecessor,temp_map})
    end)
  end

  # This method queries a key on a specific node. This is called by
  # queryKey method.  
          
  def findKey(key_map, pid, key, hops) do
    
    if elem(key_map[key], 0) == pid do
     
      IO.puts "The key is located and the string associated with it is #{elem(key_map[key], 1)}"
      IO.puts " "
      hops
    else
      ft = GenServer.call(pid, {:fetch_finger_table})
      nid = findHighestPredecessor(ft, key)
      findKey(key_map, nid, key, hops+1)
    end
  end

  # This method finds the closest predecessor of a key in the finger table of a node.
      
  def findHighestPredecessor(ft, key) do
    key_list = Map.keys(ft)
    # IO.inspect ft
    v = Enum.reduce(key_list, -1, fn(x),acc -> 
        if x <= key do 
          acc=x 
        else 
          acc  
        end 
      end)
    if v == -1 do
      v = Enum.at(key_list, -1)
      ft[v]
    else
      ft[v]
    end
  end

  # This method initializes the keys with a random string.

  def createKeys(node_list, key_space_size, m) do
    keys_map = %{}
    keys_map = Enum.reduce(node_list, %{}, fn(x), acc1 -> 
        pid = elem(x, 1)
        predecessor = GenServer.call(pid, {:fetch_pred})
        pred_id = GenServer.call(predecessor, {:fetch_arg})
        node_id = GenServer.call(pid, {:fetch_arg})  

        acc1 = cond do
          node_id > pred_id ->
              temp =  Enum.reduce(pred_id+1..node_id, %{}, fn(x), acc -> 
                Map.put(acc, x, {pid, randstr()})
              end)
              Map.merge(acc1, temp)
          true ->
              temp =  Enum.reduce(1..(key_space_size+node_id-pred_id), %{}, fn(x), acc -> 
                key = rem(pred_id+x,key_space_size)
                Map.put(acc, key, {pid, randstr()})
              end)
              Map.merge(acc1, temp)
        end
      end)
    keys_map
  end

  def getKeySpaceSizeAndM(numNodes, i) do 
    if :math.pow(2, i) > numNodes do
      {trunc(:math.pow(2, i)),i}
    else
      getKeySpaceSizeAndM(numNodes, i+1)
    end
  end

end



