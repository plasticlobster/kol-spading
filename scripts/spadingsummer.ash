record fake_item {
   string descid;
   string name;
};

record summer_effect {
   effect ef;
   string description;
};

record summer_item {
   item it;
   string name;
   summer_effect ef;
   int effect_turns;
   string type;
};

record fake_summer_item {
   fake_item it;
   string name;
   summer_effect ef;
   int effect_turns;
   string type;
};

record summer_consumable {
   summer_item it;
   string type;
   int capacity;
   string quality;
};

record fake_summer_consumable {
   fake_summer_item it;
   string type;
   int capacity;
   string quality;
};

string to_string_se(summer_effect ef) {
   return ef.ef.descid+"|"+to_string(ef.ef)+"|"+ef.description;
}
string to_string_si(summer_item it) {
   return it.it.descid+"|"+to_string(it.it)+"|"+it.name+"|"+it.type+"|"+to_string_se(it.ef)+"|"+it.effect_turns;
}
string to_string_sc(summer_consumable sc) {
   return sc.type+"|"+sc.quality+"|"+sc.capacity+"|"+to_string_si(sc.it);
}

string to_string_fsi(fake_summer_item it) {
   return it.it.descid+"|"+it.it.name+"|"+it.name+"|"+it.type+"|"+to_string_se(it.ef)+"|"+it.effect_turns;
}
string to_string_fsc(fake_summer_consumable sc) {
   return sc.type+"|"+sc.quality+"|"+sc.capacity+"|"+to_string_fsi(sc.it);
}

summer_item[int] submit_items(summer_item[int] summer_items) {
   string post_url_items = "http://www.plasticlobster.com/summer/summer_items.php?version=3&class="+url_encode(my_class())+"&sign="+url_encode(my_sign());
   foreach a in summer_items {
      if (summer_items[a].name == "") {
         abort("An error occurred processing item: " + to_string_si(summer_items[a]));
      }
      post_url_items += "&items[]="+url_encode(to_string_si(summer_items[a]));
   }

   if (count(summer_items) > 0) {
      print("Submitting items");
      buffer res = visit_url(post_url_items);
      print(res);
   }
   summer_item[int] tmp;
   return tmp;
}

summer_consumable[int] submit_consumables(summer_consumable[int] summer_consumables) {
   string post_url_consumables = "http://www.plasticlobster.com/summer/summer_consumables.php?version=3&class="+url_encode(my_class())+"&sign="+url_encode(my_sign());
   foreach a in summer_consumables {
      if (summer_consumables[a].it.name == "") {
         abort("An error occurred processing consumable: " + to_string_sc(summer_consumables[a]));
      }
      post_url_consumables += "&items[]="+url_encode(to_string_sc(summer_consumables[a]));
   }

   if (count(summer_consumables) > 0) {
      print("Submitting Consumables");
      buffer res2 = visit_url(post_url_consumables);
      print(res2);
   }
   summer_consumable[int] tmp;
   return tmp;
}


fake_summer_consumable[int] submit_fake_consumables(fake_summer_consumable[int] summer_consumables) {
   string post_url_consumables = "http://www.plasticlobster.com/summer/summer_consumables.php?version=3&class="+url_encode(my_class())+"&sign="+url_encode(my_sign());
   foreach a in summer_consumables {
      post_url_consumables += "&items[]="+url_encode(to_string_fsc(summer_consumables[a]));
   }

   if (count(summer_consumables) > 0) {
      print("Submitting Fake Consumables");
      buffer res2 = visit_url(post_url_consumables);
      print(res2);
   }
   fake_summer_consumable[int] tmp;
   return tmp;
}

fake_summer_consumable spade_fake_consumable(string desc_id, string orig_name) {
   fake_summer_item tmp_item;
   fake_item it;
   it.name = orig_name;
   it.descid = desc_id;

   tmp_item.it = it;

   buffer desc = visit_url("desc_item.php?whichitem="+desc_id);
   string [int,int] match;
   matcher aux_matcher;
   string eff_desc_id;
   effect eff;

   match = desc.group_string("<center>.*?<b>(.*?)</b></center>");
   tmp_item.name = match[0][1];
   fake_summer_consumable tmp_consumable;

   match = desc.group_string("Type: <b>(\\w+)");
   tmp_consumable.type = match[0][1];
   tmp_consumable.quality = match[0][2];

   aux_matcher = create_matcher("whicheffect\\=(\\w+)\"", desc);
   if (find(aux_matcher)) {
      eff = desc_to_effect(group(aux_matcher,1));
      summer_effect tmp_effect;
      tmp_effect.ef = eff;
      tmp_effect.description = eff.string_modifier("modifiers");

      match = desc.group_string("\\((\\d+) Adventure");
      tmp_item.effect_turns = to_int(match[0][1]);
      tmp_item.ef = tmp_effect;
   }
   match = desc.group_string("(Size|Potency|Toxicity): <b>(\\w+)(?:<br>)?</b>");
   tmp_consumable.capacity = to_int(match[0][2]);
   tmp_item.type = 'usable';
   tmp_consumable.it = tmp_item;
   return tmp_consumable;
}

summer_item spade_item(item it) {
   summer_item tmp_item;
   tmp_item.it = it;
   summer_effect tmp_effect;

   string [int,int] match;
   matcher aux_matcher;
   string eff_desc_id;
   effect eff;
   buffer desc = visit_url("desc_item.php?whichitem="+it.descid);

   match = desc.group_string("(<blockquote>|<center>).*?<b>(.*?)<\/b>(<\/center>|<br>)"); // <center>.*?<b>(.*?)</b></center>");
   tmp_item.name = match[0][2];

   match = desc.group_string("Type: <b>(\\w+)");
   tmp_item.type = match[0][1];
   eff_desc_id = desc.group_string("whicheffect\\=(\\w+)\"")[0][1];
   eff = desc_to_effect(eff_desc_id);
   tmp_effect.ef = eff;

   tmp_effect.description = eff.string_modifier("modifiers");

   match = desc.group_string("\\((\\d+) Adventure");
   tmp_item.effect_turns = to_int(match[0][1]);
   tmp_item.ef = tmp_effect;
   return tmp_item;
}

summer_item spade_other_item(item it) {
   summer_item tmp_item;
   tmp_item.it = it;
   summer_effect tmp_effect;

   string [int,int] match;
   matcher aux_matcher;
   string eff_desc_id;
   buffer desc = visit_url("desc_item.php?whichitem="+it.descid);
   match = desc.group_string("(<blockquote>|<center>).*?<b>(.*?)<\/b>(<\/center>|<br>)"); // <center>.*?<b>(.*?)</b></center>");
   tmp_item.name = match[0][2];

   match = desc.group_string("Type: <b>(\\w+)");
   tmp_item.type = match[0][1];

   eff_desc_id = "";
   tmp_effect.description = "";

   tmp_item.effect_turns = 0;
   tmp_item.ef = tmp_effect;
   return tmp_item;
}

summer_item spade_equipment(item it) {
   summer_item tmp_item;
   tmp_item.it = it;
   summer_effect tmp_effect;

   string [int,int] match;
   matcher aux_matcher;
   string eff_desc_id;
   effect eff;
   buffer desc = visit_url("desc_item.php?whichitem="+it.descid);

   match = desc.group_string("(<blockquote>|<center>).*?<b>(.*?)<\/b>(<\/center>|<br>)"); // <center>.*?<b>(.*?)</b></center>");
   tmp_item.name = match[0][2];

   match = desc.group_string("Type: <b>(\\w+)");
   tmp_item.type = match[0][1];
        
   match = desc.group_string("<center><b><font color=\"blue\">(.*?)</font></b></center>");
   aux_matcher = create_matcher("(^|<br>)(.+?)(?=$|<br>)", match[0][1]);

   tmp_effect.description = "";

   while(find(aux_matcher)) {
      if (group(aux_matcher,1) != "") {
         tmp_effect.description += ", ";
      }
      tmp_effect.description += group(aux_matcher,2);
      tmp_item.ef = tmp_effect;
   }
   return tmp_item;
}

summer_consumable spade_consumable(item it) {
   summer_item tmp_item;
   tmp_item.it = it;
   summer_effect tmp_effect;

   string [int,int] match;
   matcher aux_matcher;
   string eff_desc_id;
   effect eff;
   buffer desc = visit_url("desc_item.php?whichitem="+it.descid);

   match = desc.group_string("<center>.*?<b>(.*?)</b></center>");
   match = desc.group_string("(<blockquote>|<center>).*?<b>(.*?)<\/b>(<\/center>|<br>)"); // <center>.*?<b>(.*?)</b></center>");
   tmp_item.name = match[0][2];
   summer_consumable tmp_consumable;

   match = desc.group_string("Type: <b>(\\w+) .*?\\((.*?)\\)");
   tmp_consumable.type = match[0][1];

   tmp_consumable.quality = match[0][2];

   aux_matcher = create_matcher("whicheffect\\=(\\w+)\"", desc);
   if (find(aux_matcher)) {
      eff = desc_to_effect(group(aux_matcher,1));
      summer_effect tmp_effect;
      tmp_effect.ef = eff;
      tmp_effect.description = eff.string_modifier("modifiers");

      match = desc.group_string("\\((\\d+) Adventure");
      tmp_item.effect_turns = to_int(match[0][1]);
      tmp_item.ef = tmp_effect;
   }

   match = desc.group_string("(Size|Potency|Toxicity): <b>(\\w+)(?:<br>)?</b>");
   tmp_consumable.capacity = to_int(match[0][2]);
   tmp_item.type = 'usable';
   tmp_consumable.it = tmp_item;
   return tmp_consumable;
}

void main() {
   if (my_path() != "Two Crazy Random Summer") {
      print("go away");
      exit;
   }

   print("Downloading a list of currently-known items so we don't hammer the servers unnecessarily");
   int[string] known_items;
   file_to_map("http://plasticlobster.com/summer/summer_progress.php?nonce="+random(1000000000)+"&ms="+url_encode(my_sign())+"&class="+url_encode(my_class()), known_items);

   summer_item[int] summer_items;
   summer_consumable[int] summer_consumables;

   int i;
   int j = 1;
   foreach it in $items[] {
      i = to_int(it);
      if (!(known_items[it.descid] > 0)) {
         if (it.usable && it.string_modifier("effect") != "") {
            summer_items[count(summer_items)] = spade_item(it);
            j++;
         }
         else if (it.quality != "" || it.fullness != 0 || it.inebriety != 0 || it.spleen != 0) {
            summer_consumables[count(summer_consumables)] = spade_consumable(it);
            j++;
         }
         else if (to_slot(it) != $slot[none]) {
            summer_items[count(summer_items)] = spade_equipment(it);
            j++;
         } else {
            summer_items[count(summer_items)] = spade_other_item(it);
            j++;
         }
      }
      if (j % 25 == 0) {
         print("Spading Item #"+to_int(i) + ' / 10232', "green");
      }
      if (count(summer_items) > 24) {
         summer_items = submit_items(summer_items);
         waitq(3);
      }
      if (count(summer_consumables) > 24) {
         summer_consumables = submit_consumables(summer_consumables);
         waitq(3);
      }
   }

   print("Doing Final Submissions For Inventory-able Items");
   if (count(summer_items) > 0) {
      summer_items = submit_items(summer_items);
   }
   if (count(summer_consumables) > 0) {
      summer_consumables = submit_consumables(summer_consumables);
   }

   print("Checking Non-Inventory-able Items (Like Microbrewery and Chez Snootee)");

   string[string] fake_item_list;
   file_to_map("http://plasticlobster.com/summer/fakeitems.txt", fake_item_list);

   fake_summer_consumable[int] fake_summer_consumables;

   string b;
   j = 1;
   i = 1;
   foreach b in fake_item_list {
      //b is the item name, fake_item_list[b] is the desc_id
      if (!(known_items[fake_item_list[b]] > 0)) {
         fake_summer_consumable tmp_consumable = spade_fake_consumable(fake_item_list[b], b);
         if (tmp_consumable.it.name == '') {
            print("Skipping item " + b + " because it doesn't seem to exist.", "red");
         } else {
            fake_summer_consumables[count(fake_summer_consumables)] = tmp_consumable;
         }
         j++;
      }
      if (j % 25 == 0) {
         print("Spading Item #"+ i + ' / ' + count(fake_item_list), "green");
      }
      if (count(fake_summer_consumables) > 24) {
         fake_summer_consumables = submit_fake_consumables(fake_summer_consumables);
         waitq(3);
      }
      i++;
   }
   if (count(fake_summer_consumables) > 0) {
      print("Doing a final submission of fake consumables");
      fake_summer_consumables = submit_fake_consumables(fake_summer_consumables);
   }
   print("Done! Thank you for your submission.");
}
