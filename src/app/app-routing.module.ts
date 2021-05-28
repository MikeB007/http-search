
import { Routes, RouterModule } from '@angular/router';

import { NewsStatsComponent } from './news-stats/news-stats.component';
import { NewsSearchComponent } from './news-search/news-search.component';
import { UnderConstructionComponent } from './under-construction/under-construction.component';
import { NewsDashComponent } from './news-dash/news-dash.component';

import { NgModule } from '@angular/core';


const routes: Routes = [
  {path: 'search',component:NewsSearchComponent},
  {path: 'mydash',component: NewsDashComponent},
  {path: 'source/FOXNEWS', component: UnderConstructionComponent, outlet: "source" },
  {path: 'stats',component: NewsStatsComponent},
  {path: 'underConstruction',component: UnderConstructionComponent},
  {path: '**',component:NewsDashComponent },


];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule { }


