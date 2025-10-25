import { ShowProfileComponent } from './stocks/show-profile/show-profile.component';

import { Routes, RouterModule } from '@angular/router';

import { NewsSearchComponent } from './news-search/news-search.component';
import { NewsFindComponent } from './news-find/news-find.component';
import { UnderConstructionComponent } from './under-construction/under-construction.component';
import { NewsDashComponent } from './news-dash/news-dash.component';
import { NewsNavComponent } from './news-nav/news-nav.component';


import { NgModule } from '@angular/core';
import { CompanyDashComponent } from './company-dash/company-dash.component';


const routes: Routes = [
  {path: '',component:NewsDashComponent},
  {path: 'find/:key',component:NewsFindComponent},
  {path: 'search/:key',component:NewsDashComponent},
  {path: 'searchCompany/:key',component:CompanyDashComponent},
  {path: 'mydash',component: NewsDashComponent},
  {path: 'source/FOXNEWS', component: UnderConstructionComponent, outlet: "source" },
  {path: 'underConstruction',component: UnderConstructionComponent},
  {path: 'searchi/*',component:NewsDashComponent },
  {path: '**',component:NewsDashComponent},
];

@NgModule({
  imports: [RouterModule.forRoot(routes,  {useHash:true})],
  exports: [RouterModule]
})
export class AppRoutingModule { }
