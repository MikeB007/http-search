
import { Routes, RouterModule } from '@angular/router';

import { NewsSearchComponent } from './news-search/news-search.component';
import { NewsFindComponent } from './news-find/news-find.component';
import { UnderConstructionComponent } from './under-construction/under-construction.component';
import { NewsDashComponent } from './news-dash/news-dash.component';
import { NewsNavComponent } from './news-nav/news-nav.component';


import { NgModule } from '@angular/core';


const routes: Routes = [
  {path: 'find/:key',component:NewsFindComponent},
  {path: 'search/:key',component:NewsDashComponent},
  {path: 'mydash',component: NewsDashComponent},
  {path: 'source/FOXNEWS', component: UnderConstructionComponent, outlet: "source" },
  {path: 'underConstruction',component: UnderConstructionComponent},
  {path: 'searchi/*',component:NewsDashComponent },
  {path: '**',component:UnderConstructionComponent},
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule { }
