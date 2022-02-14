
# Hi, I'm Benjamin! 👋


## 🚀 About Me
I'm currently working @ Azure Cloud where I enjoy my time!


# Bicep Modules

Bicep modules enables us to break a complex template into parts. With this in mind, we can ensure that each module is focused on a spesific task, and that the modules are reusable for multiple deployments and workloads. 

Modules are just nothing more than independent Bicep files. Often they will typically contain sets of resources that are deployed togheter as one. Modules can be consumed from any other Bicep template. 

Your might asking, what is the benefits of modules? 

Often you will be doing provisioning of cloud resources by using many individual Bicep files. Over time, these templates grow and expand significantly. What we then will end up with, is monolithic code that is really difficult to read and navigate, and yikes.., even harder to maintain! The opposite of what we are trying to achieve... 

This approach also forces you to duplicate parts of your code (even more yikes) when you want to reuse it in other templates. When you change something, you need to search trough multiple files and update them all!

Bicep modules help you address these major challenges by splitting code into smaller, more manageable files that can be referenced from multiple templates. 

Key benifits your might asking?

Reusability. Can be reused in multiple Bicep files, even if the files are for different projects or workloads. You can share modules within your team, organization or with the community (like me!).

Encapsulation. Modules helps us keeping related resource definitions together. Often when defining, you typically deploy several components. These are components that are defined seperately by themselves, but they do represent a logical grouping of resources. Might make sense to define them as a module?

Then, by doing this, your main template does not need to be aware of the details of how something is deployed. That is the resposibility of the module.

Composability. When you have created a set of modules, you can compose them together. You might create a module that deploys a Cosmos DB, and another module that deploys a virtual network. You define parameters and outputs for each module so that you can take the important information from one and send it to the other!

Functionality. In some certain scenarios, you might need to use modules to access certain functionality. You can use modules and loops together to deploy multiple sets of resources. You can also use modules to define resources at different scopes in a single deployment.

At last...

A module is just a normal Bicep file. There is nothing special about it, you create it just like you do any other Bicep file!




## Features

- Deploy and scripts folder with pipeline and scripts to automatically upload added or changed modules from repository to Azure Container Registry. It is even the tagging modules for you! 
- Module folder with several different Bicep modules.



## Feedback

If you have any feedback or things you want to see from me, pull request me! 
